#!/bin/bash


PREVIOUS_VERSION=`sudo yum list --showduplicates hootenanny-autostart | awk '{ print $2 }' | tail -n 2 | head -n 1 |sed 's/-[0-9]*.el7//g'`
sudo yum -y install hootenanny-autostart-${PREVIOUS_VERSION}
