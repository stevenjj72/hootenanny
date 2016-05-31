#!/usr/bin/env bash

HOOT_HOME=$HOME/hoot
echo HOOT_HOME: $HOOT_HOME
cd ~

# Now setup Centos
# Setup the Hoot repo so we get all of the things needed to build Hoot
echo "[hoot]" | sudo tee /etc/yum.repos.d/hoot.repo
echo "name=hoot" | sudo tee -a /etc/yum.repos.d/hoot.repo
echo "baseurl=https://s3.amazonaws.com/hoot-rpms/snapshot/el6/" | sudo tee -a /etc/yum.repos.d/hoot.repo
echo "gpgcheck=0" | sudo tee -a /etc/yum.repos.d/hoot.repo

sudo yum -y update
#sudo yum -y install hootenanny-core >> Centos_Update.txt 2>&1
sudo yum -y install hootenanny-core-deps
sudo yum -y install hootenanny-core-devel-deps
sudo yum -y install hootenanny-services-devel-deps
sudo yum -y install tomcat6

# Make sure these start
sudo chkconfig tomcat6 on

sudo chkconfig postgresql-9.2 on
sudo service postgresql-9.2 start



# Workaround for our GEOS package being skipped due to the Redhat one being "newer"
#cd /home/vagrant/workspace/el6
# if rpm -qa | grep --quiet geos-3; then
#     sudo rpm -U --oldpackage geos-3.4.2-1.el6.x86_64.rpm geos-devel-3.4.2-1.el6.x86_64.rpm
# fi

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

if ! grep --quiet "export HOOT_HOME" ~/.bash_profile; then
    echo "Adding hoot home to profile..."
    echo "export HOOT_HOME=\$HOME/hoot" >> ~/.bash_profile
    echo "export PATH=\$PATH:\$HOOT_HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

if ! grep --quiet "export JAVA_HOME" ~/.bash_profile; then
    echo "Adding Java home to profile..."
    echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk.x86_64" >> ~/.bash_profile
    source ~/.bash_profile
fi

if ! grep --quiet "export HADOOP_HOME" ~/.bash_profile; then
    echo "Adding Hadoop home to profile..."
    #echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bash_profile
    echo "export HADOOP_HOME=\$HOME/hadoop" >> ~/.bash_profile
    echo "export PATH=\$PATH:\$HADOOP_HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

if ! grep --quiet "PATH=" ~/.bash_profile; then
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

# NOTE: These have been changed to pg9.2
if ! sudo -u postgres psql -lqt | grep -i --quiet hoot; then
    echo "### Creating Services Database..."
    sudo -u postgres createuser --superuser hoot
    sudo -u postgres psql -c "alter user hoot with password 'hoottest';"
    sudo -u postgres createdb hoot --owner=hoot
    sudo -u postgres createdb wfsstoredb --owner=hoot
    sudo -u postgres psql -d hoot -c 'create extension hstore;'
    sudo -u postgres psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='wfsstoredb'" > /dev/null
    sudo -u postgres psql -d wfsstoredb -c 'create extension postgis;' > /dev/null
fi

if ! sudo -u postgres grep -i --quiet HOOT /var/lib/pgsql/9.2/data/postgresql.conf; then
echo "### Tuning PostgreSQL..."
sudo -u postgres sed -i.bak s/^max_connections/\#max_connections/ /var/lib/pgsql/9.2/data/postgresql.conf
sudo -u postgres sed -i.bak s/^shared_buffers/\#shared_buffers/ /var/lib/pgsql/9.2/data/postgresql.conf
sudo -u postgres bash -c "cat >> /var/lib/pgsql/9.2/data/postgresql.conf" <<EOT

#--------------
# Hoot Settings
#--------------
max_connections = 1000
shared_buffers = 1024MB
max_files_per_process = 1000
work_mem = 16MB
maintenance_work_mem = 256MB
autovacuum = off
EOT
fi

# Update shared memory limits in OS
if ! sysctl -e kernel.shmmax | grep --quiet 1173741824; then
    echo "### Setting kernel.shmmax..."
    sudo sysctl -w kernel.shmmax=1173741824
    sudo sh -c "echo 'kernel.shmmax=1173741824' >> /etc/sysctl.conf"
fi
if ! sysctl -e kernel.shmall | grep --quiet 2097152; then
    echo "### Setting kernel.shmall..."
    sudo sysctl -w kernel.shmall=2097152
    sudo sh -c "echo 'kernel.shmall=2097152' >> /etc/sysctl.conf"
fi

sudo service postgresql-9.2 restart

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
if ! groups vagrant | grep --quiet '\btomcat6\b'; then
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

if [ -f $HOOT_HOME/conf/LocalHoot.json ]; then
    echo "Removing LocalHoot.json..."
    rm -f $HOOT_HOME/conf/LocalHoot.json
fi

if [ -f $HOOT_HOME/hoot-services/src/main/resources/conf/local.conf ]; then
    echo "Removing services local.conf..."
    rm -f $HOOT_HOME/hoot-services/src/main/resources/conf/local.conf
fi

# Clean out tomcat logfile. We restart tomcat after provisioning
sudo service tomcat6 stop
sudo rm /var/log/tomcat6/catalina.out

cd ~
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
