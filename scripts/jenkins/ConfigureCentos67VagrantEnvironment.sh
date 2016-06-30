#!/bin/bash
#
# * Assumes the parent directory is the workspace. E.g.
#   * .../[jenkins workspaces]/[this project workspace]/hootenanny
# * Configure LocalConfig.pri for tests
# * Destroy vagrant instance if necessary
# * Build hoot with most things enabled
#
set -e
set -x

cd $HOOT_HOME

#scripts/jenkins/VeryClean.sh
rm -rf docs/node_modules hoot-core/tmp/ hoot-core-test/tmp tgs/tmp

# Removed the "-x" from this
git clean -d -f -f || echo "It is ok if this fails, it sometimes mysteriously doesn't clean"


# Maintain vagrant state in the parent directory so very clean will still work.
mkdir -p ../vagrant-hootenanny
[ -e .vagrant ] || ln -s ../vagrant-hootenanny .vagrant

# Update hoot-ui
git submodule update --init

# Jenkins Vagrant setup
[ -e VSphereDummy.box ] || ln -s ../vagrant/VSphereDummy.box VSphereDummy.box
[ -e VagrantfileLocal ] || ln -s ../../vagrant/VagrantfileLocal.centos67 VagrantfileLocal

# Copy words1.sqlite Db so we don't have to download it again
[ -e conf/words1.sqlite ] || ( [ -e $WORDS_HOME/words1.sqlite ] &&  cp $WORDS_HOME/words1.sqlite conf )

# This ended up with wrong permissions
chmod a+rw conf/words1.sqlite

# Grab the latest version of the software that the VagrantProvision script will try to download
cp -R ../../software.centos67 software

# Make sure we are not running
vagrant halt

REBUILD_VAGRANT=false

# Grab the Centos provision and build scripts and stomp on the Ubuntu ones.
cp scripts/jenkins/VagrantProvisionCentos67.sh VagrantProvision.sh
cp scripts/jenkins/VagrantBuildCentos67.sh VagrantBuild.sh

# Taking this out since we are copying the VagrantProvision.sh
#[ -f Vagrant.marker ] && [ Vagrant.marker -ot VagrantProvision.sh ] && REBUILD_VAGRANT=true

# On the first build of the day, rebuild everything
if [ "`date +%F`" != "`test -e ../BuildDate.txt && cat ../BuildDate.txt`" ]; then
    REBUILD_VAGRANT=true
fi

if [ $REBUILD_VAGRANT ]; then
    vagrant destroy -f
    time -p vagrant up --provider vsphere
else
    # time -p vagrant up --provision-with nfs,build,EGD,tomcat,mapnik,hadoop --provider vsphere
    time -p vagrant up --provision-with nfs,build,EGD,tomcat --provider vsphere
fi

date +%F > ../BuildDate.txt

