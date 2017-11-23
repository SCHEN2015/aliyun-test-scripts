#!/bin/bash

# get maximum NIC queue number

max=$(ethtool -l eth0 | grep "Combined:" | head -n 1 | awk '{print $2}')

# get current NIC queue number

cur=$(ethtool -l eth0 | grep "Combined:" | tail -n 1 | awk '{print $2}')

# set NIC queue number to the max if needed

if [ "$cur" != "$max" ]; then
	ethtool -L eth0 combined $max || exit 1
fi

exit 0
