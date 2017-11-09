#!/bin/bash

pem=cheshi_aliyun.pem
training_host_list="172.20.213.194 172.20.213.192"

n=0
for host in $training_host_list; do
	let n=n+1
	port=$((10080+n))
	echo "Start netserver at port $port on host $host"
	ssh -i $pem root@$host "netserver -p $port"
done

msize=1400

n=0
for host in $training_host_list; do
	let n=n+1
	let port=10080+n
	tmplog=netperf.tmplog.$n
	echo "Start netperf test at port $port on host $host"
	netperf -H $host -p $port -t UDP_STREAM -l 10 -f m -- -m $msize &> $tmplog &
done

wait

cat netperf.tmplog.* > netperf.log.1 && rm -f netperf.tmplog.*

BWtx=$(grep -w "$msize" netperf.log.1 | awk '{SUM += $6};END {print SUM}')


msize=1

n=0
for host in $training_host_list; do
        let n=n+1
	let port=10080+n
        tmplog=netperf.tmplog.$n
        echo "Start netperf test at port $port on host $host"
        netperf -H $host -p $port -t UDP_STREAM -l 10 -f m -- -m $msize &> $tmplog &
done

wait

cat netperf.tmplog.* > netperf.log.2 && rm -f netperf.tmplog.*

PPS=$(grep -w "$msize" netperf.log.2 | awk '{SUM += $4 / $3};END {print SUM}')

cat netperf.log.1
echo "====="
echo $BWtx

cat netperf.log.2
echo "====="
echo $PPS



