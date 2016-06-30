#!/usr/bin/env bash

set -e

#cd $HOOT_HOME
cd hoot
source ./SetupEnv.sh


echo "### Configuring Hoot..."
echo HOOT_HOME: $HOOT_HOME

#aclocal && autoconf && autoheader && automake && ./configure --quiet --with-rnd --with-services

export JAVA_HOME=/etc/alternatives/jre_1.7.0

# The dir configurations set the install directory to work with EL's dir structure
./configure --with-rnd --with-services -q \
    --prefix=/usr/ \
    --datarootdir=/usr/share/hootenanny/ \
    --docdir=/usr/share/doc/hootenanny/ \
    --localstatedir=/var/lib/hootenanny/ \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc/

echo "### Building Hoot... "
make -s clean && make -sj$(nproc)

# docs build is always failing the first time during the npm install portion for an unknown reason, but then
# always passes the second time its run...needs fixed, but this is the workaround for now
make -sj$(nproc) docs &> /dev/null || true
make -sj$(nproc) docs

### For the future
# This may be causing failure due to node-mapnik dependency on
# Requires: libc.so.6(GLIBC_2.14)(64bit)
# Install node modules
#cd node-mapnik-server
#npm install

echo "### Installing Hoot... "

# WebApps Cleanup
sudo rm -rf /var/lib/tomcat6/webapps/hoot-services
sudo rm -rf /var/lib/tomcat6/webapps/hootenanny-id

# UI stuff
sudo cp hoot-services/target/hoot-services*.war /var/lib/tomcat6/webapps/hoot-services.war
sudo chown tomcat:tomcat /var/lib/tomcat6/webapps/hoot-services.war

sudo cp -R hoot-ui/ /var/lib/tomcat6/webapps/hootenanny-id
sudo chown -R tomcat:tomcat /var/lib/tomcat6/webapps/hootenanny-id

### For the future
# mkdir -p /etc/init.d
# cp node-mapnik-server/init.d/centos-rpm /etc/init.d/node-mapnik-server
# mkdir -p /var/lib/hootenanny
# cp -R node-mapnik-server/ /var/lib/hootenanny/node-mapnik-server

# Install so we can run the UI if we want to.
sudo make install

sudo cp -R test-files/ /var/lib/hootenanny/
#sudo ln -s /usr/lib64 /var/lib/hootenanny/lib

# This allows all the tests to run.
sudo mkdir -p /var/lib/hootenanny/hoot-core-test/src/test/
sudo ln -s /var/lib/hootenanny/test-files/ /var/lib/hootenanny/hoot-core-test/src/test/resources
sudo mkdir -p /var/lib/hootenanny/test-output
sudo chmod 777 /var/lib/hootenanny/test-output


# This makes it so HootEnv.sh resolves hoot home properly.
sudo rm /usr/bin/HootEnv.sh
sudo ln -s /var/lib/hootenanny/bin/HootEnv.sh /usr/bin/HootEnv.sh

hoot version

