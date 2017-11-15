#!/bin/bash

# This script run on test and peer host.

# check netperf
type netperf &>/dev/null
if [ $? -eq 0 ]; then
    $res1="PASS"
else
    $res1="FAIL"
fi

# check multiple queue
if [ "$(ethtool -l eth0 | grep "^Combined:" | sort -u | wc -l)" = "1" ]; then
    $res2="PASS"
else
    $res2="FAIL"
fi

# check rps
if [ "$(grep f /sys/class/net/eth0/queues/rx-*/rps_cpus | wc -l)" != "0" ]; then
    $res3="PASS"
else
    $res3="FAIL"
fi

# Show summary
echo "Netperf:$res1 NIC_Queue:$res2 RPS:$res3"

exit 0
