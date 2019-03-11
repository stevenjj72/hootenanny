#!/bin/bash

USERNAME=$1
PASSWORD=$2
BRANCH_NAME=$3

if [ -z $USERNAME ] || [ -z $PASSWORD ] || [ -z $BRANCH_NAME ]; then
    echo '''Usage: ./checkHootRpmUpdate.sh username password branch_name

    username    valid username with build permissions in Jenkins
    password    the password to authenticate with Jenkins
    branch      the branch name to build for the Hootenanny-rpms pipeline
'''
fi


currentPrev=`aws s3 ls s3://hoot-repo/el7/release/ | grep hootenanny-autostart | awk '{ print \$4 }' | tail -n 2 | head -n 1 | sed 's/hootenanny-autostart-//g' | sed 's/-[0-9]*.el7.noarch.rpm//g'`

if [ "$currentPrev" != "$PREV_HOOT_RELEASE_VERSION" ]
    sudo sed "s/$PREV_HOOT_RELEASE_VERSION/$currentPrev/g" -i /etc/profile.d/hoot.sh
    export PREV_HOOT_RELEASE_VERSION="$currentPrev"
    source /etc/profile.d/hoot.sh
    sudo java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://10.194.38.26:8080 \
         -auth $USERNAME:$PASSWORD build Hootenanny-rpms/$BRANCH_NAME -f -v
fi

