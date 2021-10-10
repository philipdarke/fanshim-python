#!/bin/bash

LIBRARY_VERSION=`cat library/setup.cfg | grep version | awk -F" = " '{print $2}'`
LIBRARY_NAME=`cat library/setup.cfg | grep name | awk -F" = " '{print $2}'`

printf "$LIBRARY_NAME $LIBRARY_VERSION un-installer\n"

if [ $(id -u) -ne 0 ]; then
	printf "Script must be run as root. Try 'sudo ./uninstall.sh'\n"
	exit 1
fi

cd library

printf "Un-installing for Python 3...\n"
pip3 uninstall $LIBRARY_NAME

cd ..

printf "Done!\n"
