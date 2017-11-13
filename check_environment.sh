#!/bin/bash

# This script run on test and peer host.

# main
pem=~/cheshi_aliyun.pem
peer_host_list=${@:-"172.20.213.194 172.20.213.192"}
logfile=./netperf.full.log
vmsize="Unknown"

# check netperf
type netperf &>/dev/null
[ $? -ne 0 ] && echo "Failed to check netperf." && exit 1

# check multiple queue
[ "$(ethtool -l eth0 | grep "^Combined:" | sort -u | wc -l)" != "1" ] && echo "Failed to check NIC queue." && exit 1

# check rps
[ "$(grep 0 /sys/class/net/eth0/queues/rx-*/rps_cpus | wc -l)" != 0 ] && echo "Failed to check RPS." && exit 1

# passed
echo "All check passed."

exit 0
