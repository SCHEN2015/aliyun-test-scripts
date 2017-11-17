#!/bin/bash

# Description:
# This script is used to ensure fio is available.

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace

type fio >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then

	# install for redhat
	sudo yum install -y wget libaio-devel

	# setup fio
	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/f/fio-2.2.8-2.el7.x86_64.rpm
	sudo yum localinstall -y ./fio*.rpm
else
	sudo apt install -y git gcc libaio-devel

	git clone https://github.com/axboe/fio/

	cd fio
	./configure && make && sudo make install || exit 1
fi

exit 0

