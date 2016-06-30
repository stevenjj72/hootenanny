#!/usr/bin/env bash

set -x

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

# Update the Hoot and other repos
sudo yum --enablerepo=hoot clean metadata

# Trying this _after_ hoot is installed
sudo yum -y update

#sudo yum -y install hootenanny-core >> Centos_Update.txt 2>&1

#sudo yum -y install hootenanny-core-deps
#sudo yum -y install hootenanny-core-devel-deps
# sudo yum -y install hootenanny-services-devel-deps
# sudo yum -y install tomcat6 ccache npm

# Trying one line
sudo yum -y install hootenanny-core-deps hootenanny-core-devel-deps hootenanny-services-devel-deps tomcat6 ccache npm mocha

# Trying this _after_ hoot is installed
#sudo yum -y update

# Install Mocha for services tests
sudo npm install --silent -g mocha
sudo rm -rf $HOME/tmp

echo "### Configuring environment..."

if [ -f $HOOT_HOME/conf/LocalHoot.json ]; then
    echo "Removing LocalHoot.json..."
    rm -f $HOOT_HOME/conf/LocalHoot.json
fi

if [ -f $HOOT_HOME/hoot-services/src/main/resources/conf/local.conf ]; then
    echo "Removing services local.conf..."
    rm -f $HOOT_HOME/hoot-services/src/main/resources/conf/local.conf
fi

cd $HOOT_HOME

# Use ccache if it is available
cp LocalConfig.pri.orig LocalConfig.pri
command -v ccache >/dev/null 2>&1 && echo "QMAKE_CXX=ccache g++" >> LocalConfig.pri

# This is for later in the build
sudo sh -c "echo 'export HOOT_HOME=/var/lib/hootenanny' > /etc/profile.d/hootenanny.sh"
sudo chmod 755 /etc/profile.d/hootenanny.sh

echo "### Configure Tomcat..."
# Tomcat environment
sudo mkdir -p /var/lib/tomcat6/webapps
sudo chown tomcat:tomcat /var/lib/tomcat6/webapps

# create the osm api test db
$HOOT_HOME/scripts/SetupOsmApiDB.sh

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
TMP_HOME=/var/lib/hootenanny/tmp
if [ ! -d $TMP_HOME ]; then
    echo "Creating tmp directory for webapp"
    sudo mkdir -p $TMP_HOME
    sudo chown tomcat:tomcat $TMP_HOME
fi
REPORT_HOME=/var/lib/hootenanny/data/reports
if [ ! -d $REPORT_HOME ]; then
    echo "Creating data/reports directory for webapp"
    sudo mkdir -p $REPORT_HOME
    sudo chown tomcat:tomcat $REPORT_HOME
    sudo chown tomcat:tomcat $REPORT_HOME/..
fi


echo "### Configure AutoStart..."
# set Postgres to autostart
export PG_VERSION=$(sudo -u postgres psql -c 'SHOW SERVER_VERSION;' | egrep -o '[0-9]{1,}\.[0-9]{1,}')
sudo /sbin/chkconfig --add postgresql-$PG_VERSION
sudo /sbin/chkconfig postgresql-$PG_VERSION on
# set Tomcat to autostart
sudo /sbin/chkconfig --add tomcat6
sudo /sbin/chkconfig tomcat6 on

## For the future
# set NodeJS node-mapnik-server to autostart
#sudo /sbin/chkconfig --add node-mapnik-server
#sudo /sbin/chkconfig node-mapnik-server on


### Stop here, Hadoop will be added in later ###
exit

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

  sudo sed -i.bak 's/# export JAVA_HOME=\/usr\/lib\/j2sdk1.5-sun/export JAVA_HOME=\/usr\/lib\/jvm\/java-1.8.0-openjdk-1.8.0.91-1.b14.el6.x86_64/g' $HADOOP_HOME/conf/hadoop-env.sh
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
  # Testing indicates that the 1.8.0 Java is "1", 1.7.0 is "2"
  #echo '1' | sudo update-alternatives --config java
  echo '2' | sudo update-alternatives --config java
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

