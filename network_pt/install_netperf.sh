#!/bin/bash

# This script is used in VM

type netperf && echo "Already installed." && exit 0

#curl -O https://codeload.github.com/HewlettPackard/netperf/tar.gz/netperf-2.5.0
#mv netperf-2.5.0 netperf-2.5.0.tar.gz
#tar -zxvf netperf-2.5.0.tar.gz
#cd netperf-netperf-2.5.0
#./configure && make && make install && cd ..

cat /etc/redhat-release | grep "release 7" &>/dev/null
if [ $? -eq 0 ]; then
	# on RHEL7
	curl -O ftp://rpmfind.net/linux/mageia/distrib/3/x86_64/media/core/release/netperf-2.5.0-2.mga3.x86_64.rpm
fi

cat /etc/redhat-release | grep "release 6" &>/dev/null
if [ $? -eq 0 ]; then
	# on RHEL6
	curl -O http://rpmfind.net/linux/mageia/distrib/2/x86_64/media/core/release/netperf-2.5.0-1.mga2.x86_64.rpm
fi

rpm -ivh netperf-*.rpm

netperf -h
netserver -h 

exit 0
