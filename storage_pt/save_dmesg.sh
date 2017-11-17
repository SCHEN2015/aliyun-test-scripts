#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# This script is used to save dmesg to log

inst_type=$(metadata.sh -t | awk '{print $2}')
#inst_id=$(metadata.sh -i | awk '{print $2}')
time_stamp=$(timestamp.sh)
#logfile=~/workspace/log/dmesg_${inst_type}_${inst_id}_${time_stamp}.log
logfile=~/workspace/log/dmesg_${inst_type}_${time_stamp}.log

function log_dmesg(){
	echo -e "\n$ dmesg $@\n------------------" >> $logfile
	dmesg $@ >> $logfile
}

log_dmesg -l emerg
log_dmesg -l alert
log_dmesg -l crit
log_dmesg -l err
log_dmesg -l warn
log_dmesg -l notice
log_dmesg -l info
log_dmesg -l debug

exit 0

