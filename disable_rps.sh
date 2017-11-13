#!/bin/bash

# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j

for rps_file in $(ls /sys/class/net/eth0/queues/rx-*/rps_cpus)
do
	echo 0 > $rps_file
done

