#!/usr/bin/env bash

set -x

HOOT_HOME=$HOME/hoot
echo HOOT_HOME: $HOOT_HOME
cd ~

# Centos doesn't have this file
touch ~/.profile

# Now setup Centos
# Setup the Hoot repo so we get all of the things needed to build Hoot
echo "[hoot]" | sudo tee /etc/yum.repos.d/hoot.repo
echo "name=hoot" | sudo tee -a /etc/yum.repos.d/hoot.repo
# echo "baseurl=https://s3.amazonaws.com/hoot-rpms/snapshot/el6/" | sudo tee -a /etc/yum.repos.d/hoot.repo
echo "baseurl=https://s3.amazonaws.com/hoot-rpms/stable/el6/" | sudo tee -a /etc/yum.repos.d/hoot.repo
echo "gpgcheck=0" | sudo tee -a /etc/yum.repos.d/hoot.repo


# Link $HOOT_HOME and /var/lib/hootenanny so we can use the stuff in the RPM's and also build Hoot
#sudo ln -s $HOOT_HOME /var/lib/hootenanny

sudo yum -y update

#sudo yum -y install hootenanny-core >> Centos_Update.txt 2>&1
sudo yum -y install hootenanny-core-deps
sudo yum -y install hootenanny-core-devel-deps
sudo yum -y install hootenanny-services-devel-deps

sudo yum -y install tomcat6 ccache

# cd away from $HOME to avoid postgres warnings
cd /tmp

##### Taken from the Hoot RPM spec file. We are using the "autostart" bit
    # init and start Postgres
    PG_SERVICE=$(ls /etc/init.d | grep postgresql-)
    sudo service $PG_SERVICE initdb
    sudo service $PG_SERVICE start
  sudo /sbin/chkconfig --add postgresql-$PG_VERSION
  sudo /sbin/chkconfig postgresql-$PG_VERSION on

    export PG_VERSION=$(sudo -u postgres psql -c 'SHOW SERVER_VERSION;' | egrep -o '[0-9]{1,}\.[0-9]{1,}')

    sudo service tomcat6 start
  sudo /sbin/chkconfig --add tomcat6
  sudo /sbin/chkconfig tomcat6 on

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
    sudo -i $HOOT_HOME/scripts/SetupOsmApiDB.sh

    # Create Tomcat context path for tile images
    TOMCAT_SRV=/etc/tomcat6/server.xml
    if ! grep -i --quiet 'ingest/processed' $TOMCAT_SRV; then
        sudo -u tomcat cp $TOMCAT_SRV $TOMCAT_SRV.orig
        echo "Adding Tomcat context path for tile images"
        sudo sed -i "s@<\/Host>@ <Context docBase=\"$HOOT_HOME\/ingest\/processed\" path=\"\/static\" \/>\n &@" $TOMCAT_SRV
    fi
    # Allow linking in Tomcat context
    TOMCAT_CTX=/etc/tomcat6/context.xml
    if ! grep -i --quiet 'allowLinking="true"' $TOMCAT_CTX; then
        sudo -u tomcat cp $TOMCAT_CTX $TOMCAT_CTX.orig
        echo "Set allowLinking to true in Tomcat context"
        sudo sed -i "s@^<Context>@<Context allowLinking=\"true\">@" $TOMCAT_CTX
    fi
    # Create directories for webapp
    export TOMCAT_HOME=/usr/share/tomcat6
    if [ ! -d $TOMCAT_HOME/.deegree ]; then
        echo "Creating .deegree directory for webapp"
        mkdir $TOMCAT_HOME/.deegree
        #sudo chown tomcat:tomcat $TOMCAT_HOME/.deegree
    fi
    BASEMAP_UPLOAD_HOME=$HOOT_HOME/ingest/upload
    if [ ! -d $BASEMAP_UPLOAD_HOME ]; then
        echo "Creating ingest/upload directory for webapp"
        mkdir -p $BASEMAP_UPLOAD_HOME
        #sudo chown tomcat:tomcat $BASEMAP_UPLOAD_HOME
    fi
    BASEMAP_PROCESSED_HOME=$HOOT_HOME/ingest/processed
    if [ ! -d $BASEMAP_PROCESSED_HOME ]; then
        echo "Creating ingest/processed directory for webapp"
        mkdir -p $BASEMAP_PROCESSED_HOME
        #sudo chown tomcat:tomcat $BASEMAP_PROCESSED_HOME
    fi
    UPLOAD_HOME=$HOOT_HOME/upload
    if [ ! -d $UPLOAD_HOME ]; then
        echo "Creating upload directory for webapp"
        mkdir -p $UPLOAD_HOME
        #sudo chown tomcat:tomcat $UPLOAD_HOME
    fi
    CUSTOMSCRIPT_HOME=$HOOT_HOME/customscript
    if [ ! -d $CUSTOMSCRIPT_HOME ]; then
        echo "Creating customscript directory for webapp"
        mkdir -p $CUSTOMSCRIPT_HOME
        #sudo chown tomcat:tomcat $CUSTOMSCRIPT_HOME
    fi
    sudo chmod 777 $HOOT_HOME/tmp


#     # Update the db password in hoot-services war
#     source /var/lib/hootenanny/conf/DatabaseConfig.sh
#     while [ ! -f /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/db/spring-database.xml ]; do
#         echo "Waiting for hoot-services.war to deploy"
#         sleep 1
#     done
#     sudo sed -i s/password\:\ hoottest/password\:\ $DB_PASSWORD/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/db/liquibase.properties
#     sudo sed -i s/value=\"hoottest\"/value=\"$DB_PASSWORD\"/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/db/spring-database.xml
#     sudo sed -i s/dbPassword=hoottest/dbPassword=$DB_PASSWORD/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
#     sudo sed -i s/\<Password\>hoottest\<\\/Password\>/\<Password\>$DB_PASSWORD\<\\/Password\>/ /var/lib/tomcat6/webapps/hoot-services/WEB-INF/workspace/jdbc/WFS_Connection.xml
#     sudo sed -i s/\<jdbcPassword\>hoottest\<\\/jdbcPassword\>/\<jdbcPassword\>$DB_PASSWORD\<\\/jdbcPassword\>/ /var/lib/tomcat6/webapps/hoot-services/META-INF/maven/hoot/hoot-services/pom.xml
#
#     sudo service tomcat6 restart
#
#     # Apply any database schema changes
#     cd $TOMCAT_HOME/webapps/hoot-services/WEB-INF
#     liquibase --contexts=default,production \
#         --changeLogFile=classes/db/db.changelog-master.xml \
#         --promptForNonLocalDatabase=false \
#         --driver=org.postgresql.Driver \
#         --url=jdbc:postgresql:$DB_NAME \
#         --username=$DB_USER \
#         --password=$DB_PASSWORD \
#         --logLevel=warning \
#         --classpath=lib/postgresql-9.1-901-1.jdbc4.jar \
#         update

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

# if ! grep --quiet "export JAVA_HOME" ~/.bash_profile; then
#     echo "Adding Java home to profile..."
#     echo "export JAVA_HOME=/etc/alternatives/jre_1.8.0" >> ~/.bash_profile
#     source ~/.bash_profile
# fi

# if ! grep --quiet "export HADOOP_HOME" ~/.bash_profile; then
#     echo "Adding Hadoop home to profile..."
#     #echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bash_profile
#     echo "export HADOOP_HOME=\$HOME/hadoop" >> ~/.bash_profile
#     echo "export PATH=\$PATH:\$HADOOP_HOME/bin" >> ~/.bash_profile
#     source ~/.bash_profile
# fi

if ! grep --quiet "\$HOME/bin" ~/.bash_profile; then
    echo "Adding path vars to profile..."
    echo "export PATH=\$PATH:\$HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

# Make sure that we are in ~ before trying to wget & install stuff
cd ~

# Clean out tomcat logfile. We restart tomcat after provisioning
sudo service tomcat6 stop
sudo rm /var/log/tomcat6/catalina.out


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

