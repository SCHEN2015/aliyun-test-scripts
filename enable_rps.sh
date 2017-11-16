#!/bin/bash

# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j
#
#cpu_num=$(grep -c processor /proc/cpuinfo)
#
#quotient=$((cpu_num/8))
#
#if [ $quotient -gt 2 ]; then
#	quotient=2
#elif [ $quotient -lt 1 ]; then
#	quotient=1
#fi
#
#for i in $(seq $quotient)
#do
#	cpuset="${cpuset}f"
#done
#
#for rps_file in $(ls /sys/class/net/eth0/queues/rx-*/rps_cpus)
#do
#	echo $cpuset > $rps_file
#done

for rps_file in $(ls /sys/class/net/eth0/queues/rx-*/rps_cpus); do
	cpuset=$(head -n 1 $rps_file | tr "0" "f")
	echo $cpuset > $rps_file
done

#for cnt_file in $(ls /sys/class/net/eth0/queues/rx-*/rps_flow_cnt); do
#	flowcnt=4096
#	echo $flowcnt > $cnt_file
#done

exit 0
