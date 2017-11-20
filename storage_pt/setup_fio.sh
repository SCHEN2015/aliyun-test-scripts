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
	wget http://brick.kernel.dk/snaps/fio-2.2.9.tar.gz
	tar xvf fio-2.2.9.tar.gz
	cd fio-2.2.9
	./configure && make && sudo make install
	cd -
else
	sudo apt install -y git gcc libaio-devel

	git clone https://github.com/axboe/fio/

	cd fio
	./configure && make && sudo make install || exit 1
fi

exit 0

