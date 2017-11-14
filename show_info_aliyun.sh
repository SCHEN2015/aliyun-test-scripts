#!/bin/bash

# This script run on test host.

#!/bin/bash

#PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

function show(){
	# $1: Title;
	# $@: Command;

	if [ "$1" = "" ]; then
		echo -e "\n\$$@"
	else
		echo -e "\n* $1"
	fi
	echo -e "---------------"; shift
	$@ 2>&1
}


show "Time" date
show "Release" cat /etc/system-release

show "" uname -a
show "" cat /proc/cmdline
show "" systemd-analyze

show "" lsblk -p
show "" ip addr
show "Metadata" ./metadata.sh

exit 0
