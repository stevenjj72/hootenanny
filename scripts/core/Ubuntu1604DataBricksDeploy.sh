#!/usr/bin/env bash
set -e
set -x

export JDK_VERSION=1.8.0_152
export JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u152-b16/aa0333dd3019491ca4f6ddbe78cdb6d0/jdk-8u152-linux-x64.tar.gz
export JDK_TAR=jdk-8u152-linux-x64.tar.gz
export JDK_MD5=20dddd28ced3179685a5f58d3fcbecd8

export GDAL_VERSION=2.1.4

# FGDB 1.5 is required to compile using g++ >= 5.1
# https://trac.osgeo.org/gdal/wiki/FileGDB#HowtodealwithGCC5.1C11ABIonLinux
export FGDB_VERSION=1.5.1
export FGDB_URL=https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_${FGDB_VERSION}/

# Can be used on commands that have a tendency to fail due to network or similar
# issues. This will try twice and only print the output if it fails the second
# time.
function retry {
    OUTPUT=/tmp/out-`date +%N`.log
    $* &> $OUTPUT
    RESULT=$?
    if [ $RESULT != 0 ]; then
        echo "Retrying: " $*
        $* &> $OUTPUT
        RESULT=$?
        if [ $RESULT != 0 ]; then
            echo "Error: " $RESULT
            cat $OUTPUT
        fi
    fi
    rm $OUTPUT
    return $RESULT
}

echo "Updating OS..."
retry sudo apt-get -qq update
retry sudo apt-get -q -y upgrade
retry sudo apt-get -q -y dist-upgrade

echo "### Installing dependencies from repos..."
retry sudo apt-get -q -y install \
 asciidoc \
 automake \
 ccache \
 curl \
 dblatex \
 docbook-xml \
 doxygen \
 g++ \
 gdb \
 git \
 git-core \
 gnuplot \
 graphviz \
 htop \
 lcov \
 libboost-all-dev \
 libboost-dev \
 libcppunit-dev \
 libcv-dev \
 libgeos++-dev \
 libglpk-dev \
 libicu-dev \
 liblog4cxx10-dev \
 libnewmat10-dev \
 libogdi3.2-dev \
 libopencv-dev \
 libpq-dev \
 libproj-dev \
 libprotobuf-dev \
 libqt4-dev \
 libqt4-sql-psql \
 libqt4-sql-sqlite \
 libqtwebkit-dev \
 libstxxl-dev \
 libv8-dev \
 maven \
 node-gyp \
 openssh-server \
 patch \
 protobuf-compiler \
 python \
 python-dev \
 python-matplotlib \
 python-pip \
 python-setuptools \
 ruby \
 ruby-dev \
 source-highlight \
 swig \
 texinfo \
 texlive-lang-cyrillic \
 unzip \
 w3m \
 x11vnc \
 xsltproc \
 xvfb \
 zlib1g-dev \


if ! java -version 2>&1 | grep --quiet $JDK_VERSION; then
    echo "### Installing Java 8..."

    echo "$JDK_MD5  $JDK_TAR" > ./jdk.md5

    if [ ! -f ./$JDK_TAR ] || ! md5sum -c ./jdk.md5; then
        echo "Downloading ${JDK_TAR}...."
        sudo wget --quiet --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $JDK_URL
        echo "Finished download of ${JDK_TAR}"
    fi

    sudo mkdir -p /usr/lib/jvm
    sudo rm -rf /usr/lib/jvm/oracle_jdk8

    sudo tar -xzf ./$JDK_TAR
    sudo chown -R root:root ./jdk$JDK_VERSION
    sudo mv -f ./jdk$JDK_VERSION /usr/lib/jvm/oracle_jdk8

    sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/oracle_jdk8/jre/bin/java 9999
    sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/oracle_jdk8/bin/javac 9999
    echo "### Done with Java 8 install..."
fi

if ! $( hash ogrinfo >/dev/null 2>&1 && ogrinfo --formats | grep --quiet FileGDB ); then
    if [ ! -f gdal-${GDAL_VERSION}.tar.gz ]; then
        echo "### Downloading GDAL $GDAL_VERSION source..."
        wget --quiet http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-${GDAL_VERSION}.tar.gz
    fi
    if [ ! -d gdal-${GDAL_VERSION} ]; then
        echo "### Extracting GDAL $GDAL_VERSION source..."
        tar zxfp gdal-${GDAL_VERSION}.tar.gz
    fi

    FGDB_VERSION2=`echo $FGDB_VERSION | sed 's/\./_/g;'`

    # FGDB 1.5 is required to compile using g++ >= 5.1
    # https://trac.osgeo.org/gdal/wiki/FileGDB#HowtodealwithGCC5.1C11ABIonLinux
    if [ ! -f FileGDB_API_${FGDB_VERSION2}-64gcc51.tar.gz ]; then
        echo "### Downloading FileGDB API source..."
        wget --quiet $FGDB_URL/FileGDB_API_${FGDB_VERSION2}-64gcc51.tar.gz
    fi

    if [ ! -d /usr/local/FileGDB_API/lib ]; then
        echo "### Extracting FileGDB API source & installing lib..."
        sudo mkdir -p /usr/local/FileGDB_API && sudo tar xfp FileGDB_API_${FGDB_VERSION2}-64gcc51.tar.gz --directory /usr/local/FileGDB_API --strip-components 1
        sudo sh -c "echo '/usr/local/FileGDB_API/lib' > /etc/ld.so.conf.d/filegdb.conf"
    fi

    echo "### Building GDAL $GDAL_VERSION w/ FileGDB..."
    export PATH=/usr/local/lib:/usr/local/bin:$PATH
    cd gdal-${GDAL_VERSION}
    touch config.rpath
    echo "GDAL: configure"
    ./configure --quiet --with-static-proj4 --with-fgdb=/usr/local/FileGDB_API --with-pg=/usr/bin/pg_config --with-python
    echo "GDAL: make"
    make -sj$(nproc) > GDAL_Build.txt 2>&1
    echo "GDAL: install"
    sudo make -s install >> GDAL_Build.txt 2>&1
    cd swig/python
    echo "GDAL: python build"
    python setup.py build >> GDAL_Build.txt 2>&1
    echo "GDAL: python install"
    sudo python setup.py install >> GDAL_Build.txt 2>&1
    sudo ldconfig
    cd ~

    # Update the GDAL_DATA folder in ~/.profile
    if ! grep --quiet GDAL_DATA ~/.profile; then
      echo "Adding GDAL data path to profile..."
      echo "export GDAL_DATA=`gdal-config --datadir`" >> ~/.profile
      source ~/.profile
    fi
fi

