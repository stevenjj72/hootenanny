#!/usr/bin/env bash

HOOT_HOME=$HOME/hoot
echo HOOT_HOME: $HOOT_HOME
cd ~

# Now setup Centos
# Setup the Hoot repo so we get all of the things needed to build Hoot
echo "[hoot]" | sudo tee /etc/yum.repos.d/hoot.repo
echo "name=hoot" | sudo tee -a /etc/yum.repos.d/hoot.repo
# echo "baseurl=https://s3.amazonaws.com/hoot-rpms/snapshot/el6/" | sudo tee -a /etc/yum.repos.d/hoot.repo
echo "baseurl=https://s3.amazonaws.com/hoot-rpms/stable/el6/" | sudo tee -a /etc/yum.repos.d/hoot.repo
echo "gpgcheck=0" | sudo tee -a /etc/yum.repos.d/hoot.repo


# Link $HOOT_HOME and /var/lib/hootenanny so we can use the stuff in the RPM's and also build Hoot
sudo ln -s $HOOT_HOME /var/lib/hootenanny


sudo yum -y update

#sudo yum -y install hootenanny-core >> Centos_Update.txt 2>&1
sudo yum -y install hootenanny-core-deps
sudo yum -y install hootenanny-core-devel-deps
sudo yum -y install hootenanny-services-devel-deps

sudo yum -y install tomcat6


##### Taken from the Hoot RPM spec file. We are using the "autostart" bit
    # init and start Postgres
    PG_SERVICE=$(ls /etc/init.d | grep postgresql-)
    sudo service $PG_SERVICE initdb
    sudo service $PG_SERVICE start
    PG_VERSION=$(sudo -u postgres psql -c 'SHOW SERVER_VERSION;' | egrep -o '[0-9]{1,}\.[0-9]{1,}')

    sudo service tomcat6 start

    # create Hoot services db
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw hoot; then
        RAND_PW=$(pwgen -s 16 1)
        sudo -u postgres createuser --superuser hoot || true
        sudo -u postgres psql -c "alter user hoot with password '$RAND_PW';"
        sudo sed -i s/DB_PASSWORD=.*/DB_PASSWORD=$RAND_PW/ /var/lib/hootenanny/conf/DatabaseConfig.sh
        sudo -u postgres createdb hoot --owner=hoot
        sudo -u postgres createdb wfsstoredb --owner=hoot
        sudo -u postgres psql -d hoot -c 'create extension hstore;'
        sudo -u postgres psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='wfsstoredb'"
        sudo -u postgres psql -d wfsstoredb -c 'create extension postgis;'
    fi

    # configure Postgres settings
    PG_HB_CONF=/var/lib/pgsql/$PG_VERSION/data/pg_hba.conf
    if ! sudo grep -i --quiet hoot $PG_HB_CONF; then
        sudo -u postgres cp $PG_HB_CONF $PG_HB_CONF.orig
        sudo -u postgres sed -i '1ihost    all            hoot            127.0.0.1/32            md5' $PG_HB_CONF
        sudo -u postgres sed -i '1ihost    all            hoot            ::1/128                 md5' $PG_HB_CONF
    fi
    POSTGRES_CONF=/var/lib/pgsql/$PG_VERSION/data/postgresql.conf
    if ! grep -i --quiet HOOT $POSTGRES_CONF; then
        sudo -u postgres cp $POSTGRES_CONF $POSTGRES_CONF.orig
        sudo -u postgres sed -i s/^max_connections/\#max_connections/ $POSTGRES_CONF
        sudo -u postgres sed -i s/^shared_buffers/\#shared_buffers/ $POSTGRES_CONF
        sudo -u postgres bash -c "cat >> $POSTGRES_CONF" <<EOT
#--------------
# Hoot Settings
#--------------
max_connections = 1000
shared_buffers = 1024MB
max_files_per_process = 1000
work_mem = 16MB
maintenance_work_mem = 256MB
checkpoint_segments = 20
autovacuum = off
EOT
    fi
    # configure kernel parameters
    SYSCTL_CONF=/etc/sysctl.conf
    if ! grep --quiet 1173741824 $SYSCTL_CONF; then
        sudo cp $SYSCTL_CONF $SYSCTL_CONF.orig
        echo "Setting kernel.shmmax"
        sudo sysctl -w kernel.shmmax=1173741824
        sudo sh -c "echo 'kernel.shmmax=1173741824' >> $SYSCTL_CONF"
        #                 kernel.shmmax=68719476736
    fi
    if ! grep --quiet 2097152 $SYSCTL_CONF; then
        echo "Setting kernel.shmall"
        sudo sysctl -w kernel.shmall=2097152
        sudo sh -c "echo 'kernel.shmall=2097152' >> $SYSCTL_CONF"
        #                 kernel.shmall=4294967296
    fi
    sudo service postgresql-$PG_VERSION restart

    # create the osm api test db
    sudo -i /var/lib/hootenanny/scripts/SetupOsmApiDB.sh

    # Create Tomcat context path for tile images
    TOMCAT_SRV=/etc/tomcat6/server.xml
    if ! grep -i --quiet 'ingest/processed' $TOMCAT_SRV; then
        sudo -u tomcat cp $TOMCAT_SRV $TOMCAT_SRV.orig
        echo "Adding Tomcat context path for tile images"
        sudo sed -i "s@<\/Host>@ <Context docBase=\"\/var\/lib\/hootenanny\/ingest\/processed\" path=\"\/static\" \/>\n &@" $TOMCAT_SRV
    fi
    # Allow linking in Tomcat context
    TOMCAT_CTX=/etc/tomcat6/context.xml
    if ! grep -i --quiet 'allowLinking="true"' $TOMCAT_CTX; then
        sudo -u tomcat cp $TOMCAT_CTX $TOMCAT_CTX.orig
        echo "Set allowLinking to true in Tomcat context"
        sudo sed -i "s@^<Context>@<Context allowLinking=\"true\">@" $TOMCAT_CTX
    fi
    # Create directories for webapp
    TOMCAT_HOME=/usr/share/tomcat6
    if [ ! -d $TOMCAT_HOME/.deegree ]; then
        echo "Creating .deegree directory for webapp"
        sudo mkdir $TOMCAT_HOME/.deegree
        sudo chown tomcat:tomcat $TOMCAT_HOME/.deegree
    fi
    BASEMAP_UPLOAD_HOME=/var/lib/hootenanny/ingest/upload
    if [ ! -d $BASEMAP_UPLOAD_HOME ]; then
        echo "Creating ingest/upload directory for webapp"
        sudo mkdir -p $BASEMAP_UPLOAD_HOME
        sudo chown tomcat:tomcat $BASEMAP_UPLOAD_HOME
    fi
    BASEMAP_PROCESSED_HOME=/var/lib/hootenanny/ingest/processed
    if [ ! -d $BASEMAP_PROCESSED_HOME ]; then
        echo "Creating ingest/processed directory for webapp"
        sudo mkdir -p $BASEMAP_PROCESSED_HOME
        sudo chown tomcat:tomcat $BASEMAP_PROCESSED_HOME
    fi
    UPLOAD_HOME=/var/lib/hootenanny/upload
    if [ ! -d $UPLOAD_HOME ]; then
        echo "Creating upload directory for webapp"
        sudo mkdir -p $UPLOAD_HOME
        sudo chown tomcat:tomcat $UPLOAD_HOME
    fi
    CUSTOMSCRIPT_HOME=/var/lib/hootenanny/customscript
    if [ ! -d $CUSTOMSCRIPT_HOME ]; then
        echo "Creating customscript directory for webapp"
        sudo mkdir -p $CUSTOMSCRIPT_HOME
        sudo chown tomcat:tomcat $CUSTOMSCRIPT_HOME
    fi
    sudo chmod 777 /var/lib/hootenanny/tmp

    # Update the db password in hoot-services war
    source /var/lib/hootenanny/conf/DatabaseConfig.sh
    while [ ! -f /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/db/spring-database.xml ]; do
        echo "Waiting for hoot-services.war to deploy"
        sleep 1
    done
    sudo sed -i s/password\:\ hoottest/password\:\ $DB_PASSWORD/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/db/liquibase.properties
    sudo sed -i s/value=\"hoottest\"/value=\"$DB_PASSWORD\"/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/db/spring-database.xml
    sudo sed -i s/dbPassword=hoottest/dbPassword=$DB_PASSWORD/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
    sudo sed -i s/\<Password\>hoottest\<\\/Password\>/\<Password\>$DB_PASSWORD\<\\/Password\>/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/workspace/jdbc/WFS_Connection.xml
    sudo sed -i s/\<jdbcPassword\>hoottest\<\\/jdbcPassword\>/\<jdbcPassword\>$DB_PASSWORD\<\\/jdbcPassword\>/ /var/lib/tomcat6/webapps/hoot-services/META-INF/maven/hoot/hoot-services/pom.xml

    sudo service tomcat6 restart

    # Apply any database schema changes
    cd $TOMCAT_HOME/webapps/hoot-services/WEB-INF
    liquibase --contexts=default,production \
        --changeLogFile=classes/db/db.changelog-master.xml \
        --promptForNonLocalDatabase=false \
        --driver=org.postgresql.Driver \
        --url=jdbc:postgresql:$DB_NAME \
        --username=$DB_USER \
        --password=$DB_PASSWORD \
        --logLevel=warning \
        --classpath=lib/postgresql-9.1-901-1.jdbc4.jar \
        update

    # Configuring firewall
    if ! sudo iptables --list-rules | grep -i --quiet 'dport 80'; then
        sudo iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
        sudo iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
        sudo iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 8000 -j ACCEPT
        sudo iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 8094 -j ACCEPT
        sudo iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 8096 -j ACCEPT
        sudo iptables -I PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-ports 8080
        sudo iptables -I OUTPUT -t nat -s 0/0 -d 127/8 -p tcp --dport 80 -j REDIRECT --to-ports 8080
        sudo service iptables save
        sudo service iptables restart
    fi








# set Postgres to autostart
export PG_VERSION=$(sudo -u postgres psql -c 'SHOW SERVER_VERSION;' | egrep -o '[0-9]{1,}\.[0-9]{1,}')
sudo /sbin/chkconfig --add postgresql-$PG_VERSION
sudo /sbin/chkconfig postgresql-$PG_VERSION on
# set Tomcat to autostart
sudo /sbin/chkconfig --add tomcat6
sudo /sbin/chkconfig tomcat6 on
# set NodeJS node-mapnik-server to autostart
sudo /sbin/chkconfig --add node-mapnik-server
sudo /sbin/chkconfig node-mapnik-server on

##### End from Hoot RPM Spec file

# Add some stuff to get development going
# if ! dpkg -l | grep --quiet dictionaries-common; then
#     # See /usr/share/doc/dictionaries-common/README.problems for details
#     # http://www.linuxquestions.org/questions/debian-26/dpkg-error-processing-dictionaries-common-4175451951/
#     sudo apt-get -q -y install dictionaries-common >> Ubuntu_upgrade.txt 2>&1
#
#     sudo /usr/share/debconf/fix_db.pl
#
#     sudo apt-get -q -y install wamerican-insane >> Ubuntu_upgrade.txt 2>&1
#
#     sudo /usr/share/debconf/fix_db.pl
#     sudo dpkg-reconfigure -f noninteractive dictionaries-common
# fi
#

echo "### Configuring environment..."

if [ -f $HOOT_HOME/conf/LocalHoot.json ]; then
    echo "Removing LocalHoot.json..."
    rm -f $HOOT_HOME/conf/LocalHoot.json
fi

if [ -f $HOOT_HOME/hoot-services/src/main/resources/conf/local.conf ]; then
    echo "Removing services local.conf..."
    rm -f $HOOT_HOME/hoot-services/src/main/resources/conf/local.conf
fi

if ! grep --quiet "export HOOT_HOME" ~/.bash_profile; then
    echo "Adding hoot home to profile..."
    echo "export HOOT_HOME=\$HOME/hoot" >> ~/.bash_profile
    echo "export PATH=\$PATH:\$HOOT_HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

if ! grep --quiet "export JAVA_HOME" ~/.bash_profile; then
    echo "Adding Java home to profile..."
    echo "export JAVA_HOME=/etc/alternatives/jre_1.7.0" >> ~/.bash_profile
    source ~/.bash_profile
fi

if ! grep --quiet "export HADOOP_HOME" ~/.bash_profile; then
    echo "Adding Hadoop home to profile..."
    #echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bash_profile
    echo "export HADOOP_HOME=\$HOME/hadoop" >> ~/.bash_profile
    echo "export PATH=\$PATH:\$HADOOP_HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

if ! grep --quiet "\$HOME/bin" ~/.bash_profile; then
    echo "Adding path vars to profile..."
    echo "export PATH=\$PATH:\$HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

# Make sure that we are in ~ before trying to wget & install stuff
cd ~

if [ ! -f bin/osmosis ]; then
    echo "### Installing Osmosis"
    mkdir -p $HOME/bin
    if [ ! -f osmosis-latest.tgz ]; then
      wget --quiet http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
    fi
    mkdir -p $HOME/bin/osmosis_src
    tar -zxf osmosis-latest.tgz -C $HOME/bin/osmosis_src
    ln -s $HOME/bin/osmosis_src/bin/osmosis $HOME/bin/osmosis
fi

##### Start Hadoop #####
# hoot has only been tested successfully with hadoop 0.20.2, which is not available from public repos,
# so purposefully not installing hoot from the repos.
if ! which hadoop > /dev/null ; then
  echo "Installing Hadoop..."
  if [ ! -f hadoop-0.20.2.tar.gz ]; then
    wget --quiet https://archive.apache.org/dist/hadoop/core/hadoop-0.20.2/hadoop-0.20.2.tar.gz
  fi

  if [ ! -f $HOME/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
    ssh-keyscan -H localhost >> $HOME/.ssh/known_hosts
  fi
  chmod 600 $HOME/.ssh/authorized_keys

  #cd /usr/local
  cd ~
  sudo tar -zxf $HOME/hadoop-0.20.2.tar.gz
  sudo chown -R vagrant:vagrant hadoop-0.20.2
  sudo ln -s hadoop-0.20.2 hadoop
  sudo chown -R vagrant:vagrant hadoop
  cd hadoop
  sudo find . -type d -exec chmod a+rwx {} \;
  sudo find . -type f -exec chmod a+rw {} \;
  sudo chmod go-w bin
  cd ~

#TODO: remove these home dir hardcodes
sudo rm -f $HADOOP_HOME/conf/core-site.xml
sudo bash -c "cat >> /home/vagrant/hadoop/conf/core-site.xml" <<EOT

<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:9000/</value>
  </property>
</configuration>
EOT
sudo rm -f $HADOOP_HOME/conf/mapred-site.xml
sudo bash -c "cat >> /home/vagrant/hadoop/conf/mapred-site.xml" <<EOT

<configuration>
  <property>
    <name>mapred.job.tracker</name>
    <value>localhost:9001</value>
  </property>
  <property>
    <name>mapred.job.tracker.http.address</name>
    <value>0.0.0.0:50030</value>
  </property>
  <property>
    <name>mapred.task.tracker.http.address</name>
    <value>0.0.0.0:50060</value>
  </property>
  <property>
    <name>mapred.child.java.opts</name>
    <value>-Xmx2048m</value>
  </property>
  <property>
    <name>mapred.map.tasks</name>
    <value>17</value>
  </property>
  <property>
    <name>mapred.tasktracker.map.tasks.maximum</name>
    <value>4</value>
  </property>
  <property>
    <name>mapred.tasktracker.reduce.tasks.maximum</name>
    <value>2</value>
  </property>
  <property>
    <name>mapred.reduce.tasks</name>
    <value>1</value>
  </property>
</configuration>
EOT
sudo rm -f $HADOOP_HOME/conf/hdfs-site.xml
sudo bash -c "cat >> /home/vagrant/hadoop/conf/hdfs-site.xml" <<EOT

<configuration>
  <property>
    <name>dfs.secondary.http.address</name>
    <value>0.0.0.0:50090</value>
  </property>
  <property>
    <name>dfs.datanode.address</name>
    <value>0.0.0.0:50010</value>
  </property>
  <property>
    <name>dfs.datanode.http.address</name>
    <value>0.0.0.0:50075</value>
  </property>
  <property>
    <name>dfs.datanode.ipc.address</name>
    <value>0.0.0.0:50020</value>
  </property>
  <property>
    <name>dfs.http.address</name>
    <value>0.0.0.0:50070</value>
  </property>
  <property>
    <name>dfs.datanode.https.address</name>
    <value>0.0.0.0:50475</value>
  </property>
  <property>
    <name>dfs.https.address</name>
    <value>0.0.0.0:50470</value>
  </property>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
  <property>
    <name>dfs.umaskmode</name>
    <value>002</value>
  </property>
  <property>
    <name>fs.checkpoint.dir</name>
    <value>/home/vagrant/hadoop/dfs/namesecondary</value>
  </property>
  <property>
    <name>dfs.name.dir</name>
    <value>/home/vagrant/hadoop/dfs/name</value>
  </property>
  <property>
    <name>dfs.data.dir</name>
    <value>/home/vagrant/hadoop/dfs/data</value>
  </property>
</configuration>
EOT

  sudo sed -i.bak 's/# export JAVA_HOME=\/usr\/lib\/j2sdk1.5-sun/export JAVA_HOME=\/usr\/lib\/jvm\/java-1.7.0-openjdk.x86_64/g' $HADOOP_HOME/conf/hadoop-env.sh
  sudo sed -i.bak 's/#include <pthread.h>/#include <pthread.h>\n#include <unistd.h>/g' $HADOOP_HOME/src/c++/pipes/impl/HadoopPipes.cc

  sudo mkdir -p $HOME/hadoop/dfs/name/current
  # this could perhaps be more strict
  sudo chmod -R 777 $HOME/hadoop
  echo 'Y' | hadoop namenode -format

  cd /lib
  sudo ln -s $JAVA_HOME/jre/lib/amd64/server/libjvm.so libjvm.so
  cd /lib64
  sudo ln -s $JAVA_HOME/jre/lib/amd64/server/libjvm.so libjvm.so
  cd ~

  echo '1' | sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-1.7.0-openjdk.x86_64/bin/java 1
  echo '1' | sudo update-alternatives --config java
  echo '1' | sudo update-alternatives --install "/usr/bin/javac" "javac" "$JAVA_HOME/bin/javac" 1
  echo '1' | sudo update-alternatives --config javac

  # test hadoop out
  #stop-all.sh
  #start-all.sh
  #hadoop fs -ls /
  #hadoop jar ./hadoop-0.20.2-examples.jar pi 2 100
fi

cd ~
##### End Hadoop #####

exit



cd $HOOT_HOME
source ./SetupEnv.sh

if [ ! "$(ls -A hoot-ui)" ]; then
    echo "hoot-ui is empty"
    echo "init'ing and updating submodule"
    git submodule init && git submodule update
fi


# Configure Tomcat
if ! grep --quiet TOMCAT6_HOME ~/.bash_profile; then
    echo "### Adding Tomcat to profile..."
    echo "export TOMCAT6_HOME=/usr/share/tomcat6" >> ~/.bash_profile
    source ~/.bash_profile
fi

# Add tomcat6 and vagrant to each others groups so we can get the group write working with nfs
if ! groups vagrant | grep --quiet '\btomcat\b'; then
    echo "Adding vagrant user to tomcat6 user group..."
    sudo usermod -a -G tomcat vagrant
fi
if ! groups tomcat | grep --quiet "\bvagrant\b"; then
    echo "Adding tomcat6 user to vagrant user group..."
    sudo usermod -a -G vagrant tomcat
fi

if ! grep -i --quiet HOOT /etc/default/tomcat6; then
echo "Configuring tomcat6 environment..."
# This echo properly substitutes the home path dir and keeps it from having to be hardcoded, but
# fails on permissions during write...so hardcoding the home path here instead for now.  This
# hardcode needs to be removed in order for hoot dev env install script to work correctly.
#
#sudo echo "#--------------
# Hoot Settings
#--------------
#HOOT_HOME=\$HOOT_HOME/hoot" >> /etc/default/tomcat6

sudo bash -c "cat >> /etc/default/tomcat6" <<EOT

#--------------
# Hoot Settings
#--------------
HOOT_HOME=/home/vagrant/hoot
HADOOP_HOME=/home/vagrant/hadoop
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:$HOOT_HOME/lib:$HOOT_HOME/pretty-pipes/lib
GDAL_DATA=/usr/local/share/gdal
GDAL_LIB_DIR=/usr/local/lib
HOOT_WORKING_NAME=hoot
PATH=$HOOT_HOME/bin:$PATH
EOT
fi

# Trying this to try to get rid of errors
sudo mkdir -p /usr/share/tomcat6/server/classes
sudo mkdir -p /usr/share/tomcat6/shared/classes
sudo chown -R tomcat:tomcat /usr/share/tomcat6/server
sudo chown -R tomcat:tomcat /usr/share/tomcat6/shared

# Can change it to 000 to get rid of errors
if ! grep -i --quiet 'umask 002' /etc/default/tomcat6; then
echo "### Changing Tomcat umask to group write..."
sudo bash -c "cat >> /etc/default/tomcat6" <<EOT
# Set tomcat6 umask to group write because all files in shared folder are owned by vagrant
umask 002
EOT
fi

if grep -i --quiet '^JAVA_OPTS=.*\-Xmx128m' /etc/default/tomcat6; then
    echo "### Changing Tomcat java opts..."
    sudo sed -i.bak "s@\-Xmx128m@\-Xms512m \-Xmx2048m \-XX:PermSize=512m \-XX:MaxPermSize=4096m@" /etc/default/tomcat6
fi

if grep -i --quiet 'gdal/1.10' /etc/default/tomcat6; then
    echo "### Fixing Tomcat GDAL_DATA env var path..."
    sudo sed -i.bak s@^GDAL_DATA=.*@GDAL_DATA=\/usr\/local\/share\/gdal@ /etc/default/tomcat6
fi

if ! grep -i --quiet 'ingest/processed' /etc/tomcat6/server.xml; then
    echo "Adding Tomcat context path for tile images..."
    sudo sed -i.bak 's@<\/Host>@  <Context docBase=\"'"$HOOT_HOME"'\/ingest\/processed\" path=\"\/static\" \/>\n      &@' /etc/tomcat6/server.xml
fi

if ! grep -i --quiet 'allowLinking="true"' /etc/tomcat6/context.xml; then
    echo "Set allowLinking to true in Tomcat context..."
    sudo sed -i.bak "s@^<Context>@<Context allowLinking=\"true\">@" /etc/tomcat6/context.xml
fi

if [ ! -d /usr/share/tomcat6/.deegree ]; then
    echo "Creating deegree directory for webapp..."
    sudo mkdir /usr/share/tomcat6/.deegree
    sudo chown tomcat6:tomcat6 /usr/share/tomcat6/.deegree
fi



# Clean out tomcat logfile. We restart tomcat after provisioning
sudo service tomcat6 stop
sudo rm /var/log/tomcat6/catalina.out

cd ~



# Clean up after the npm install
rm -rf $HOME/tmp

cd $HOOT_HOME

rm -rf $HOOT_HOME/ingest
mkdir -p $HOOT_HOME/ingest/processed

rm -rf $HOOT_HOME/upload
mkdir -p $HOOT_HOME/upload

# Update marker file date now that dependency and config stuff has run
# The make command will exit and provide a warning to run 'vagrant provision'
# if the marker file is older than this file (VagrantProvision.sh)
#touch Vagrant.marker
# Now we are ready to build Hoot.  The VagrantBuild.sh script will build Hoot.
