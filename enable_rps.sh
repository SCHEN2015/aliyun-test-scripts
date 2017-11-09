#!/bin/bash

# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j

cpu_num=$(grep -c processor /proc/cpuinfo)

quotient=$((cpu_num/8))

if [ $quotient -gt 2 ]; then
	quotient=2
elif [ $quotient -lt 1 ]; then
	quotient=1
fi

for i in $(seq $quotient)
do
	cpuset="${cpuset}f"
done

for rps_file in $(ls /sys/class/net/eth*/queues/rx-*/rps_cpus)
do
	echo $cpuset > $rps_file
done

