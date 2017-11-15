#!/bin/bash

# This script run on test host.
# Inputs: an ip list of peer hosts


function start_server_on_peers()
{
	n=0
	for host in $peer_host_list; do
		let n=n+1
		let port=10080+n
		echo "Start netserver on peer $host, listen at $port."
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "netserver -p $port"
	done
}

function stop_server_on_peers()
{
	n=0
	for host in $peer_host_list; do
		echo "Stop netserver on peer $host."
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "pidof netserver | xargs kill -9"
	done
}

function load_test_to_peers()
{
	# Inputs : $1 = message size;
	# Outputs: $debuglog; $sdatalog; $bw : bandwidth in Mb/s; $pps : package# per second
	msize=${1:-1400}
	duration=10

	# trigger load test
	n=0
	for host in $peer_host_list; do
		let n=n+1
		let port=10080+n
		tmplog=netperf.tmplog.$n
		echo "Start netperf test at port $port to host $host"
		netperf -H $host -p $port -t UDP_STREAM -l $duration -f m -- -m $msize &> $tmplog &
	done

	wait

	# get results
	debuglog=~/debuginfo.log
	sdatalog=~/sourcedata.log

	for tmplog in $(ls netperf.tmplog.*); do
		sed -n '6p' $tmplog >> $sdatalog
		cat $tmplog >> $debuglog
		rm -f $tmplog
	done

	bw=$(cat $sdatalog | awk '{SUM += $6};END {print SUM / 1000}')
	pps=$(cat $sdatalog | awk '{SUM += $4 / $3};END {print SUM / 10000}')
}

function start_server_on_local()
{
	n=0
	for host in $peer_host_list; do
		let n=n+1
		let port=10080+n
		echo "Start netserver on localhost, listen at $port."
		netserver -p $port
	done
}

function stop_server_on_local()
{
	echo "Stop netserver on localhost."
	pidof netserver | xargs kill -9
}

function load_test_from_peers()
{
	# Inputs : $1 = message size;
	# Outputs: $debuglog; $sdatalog; $bw : bandwidth in Mb/s; $pps : package# per second
	msize=${1:-1400}
	duration=10
	localip=$(ifconfig eth0 | grep inet | awk '{print $2}')

	# trigger load test
	n=0
	for host in $peer_host_list; do
		let n=n+1
		let port=10080+n
		echo "Start netperf test at port $port from host $host"
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "netperf -H $localip -p $port -t UDP_STREAM -l $duration -f m -- -m $msize &> ~/temp.log" &
	done

	wait

	# get remote logs
	for host in $peer_host_list; do
		let n=n+1
		tmplog=netperf.tmplog.$n
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "cat ~/temp.log; rm -f ~/temp.log" &> $tmplog
	done

	# get results
	debuglog=~/debuginfo.log
	sdatalog=~/sourcedata.log

	for tmplog in $(ls netperf.tmplog.*); do
		sed -n '7p' $tmplog >> $sdatalog
		cat $tmplog >> $debuglog
		rm -f $tmplog
	done

	bw=$(cat $sdatalog | awk '{SUM += $6};END {print SUM / 1000}')
	pps=$(cat $sdatalog | awk '{SUM += $4 / $3};END {print SUM / 10000}')
}


# main
pem=~/cheshi_aliyun.pem
[ -z "$1" ] && echo "Usage: $0 <Peer's IP list>" && exit 1
peer_host_list=$1
vmsize="$(hostname)"	# Can't found instance_type in metadata, so I provisioned the instance_type into hostname.
logfile=./netperf_test_${vmsize}_$(date -u +%Y%m%d%H%M%S).log

# basic information
./show_info_aliyun.sh >> $logfile
echo -e "\n\n" >> $logfile

# Send test
echo -e "\nStart netserver..."
start_server_on_peers

echo -e "\nStart netperf test..."
load_test_to_peers 1400
echo -e "\nSend test:\n" >> $logfile
cat $debuglog >> $logfile
echo -e "\nSource data:\n" >> $logfile
cat $sdatalog >> $logfile
rm -f $debuglog $sdatalog
BWtx=$bw

echo -e "\nStart netperf test..."
load_test_to_peers 1
echo -e "\nSend test:\n" >> $logfile
cat $debuglog >> $logfile
echo -e "\nSource data:\n" >> $logfile
cat $sdatalog >> $logfile
rm -f $debuglog $sdatalog
PPStx=$pps

echo -e "\nStop netserver..."
stop_server_on_peers

echo -e "\n==========\n" >> $logfile

# Receive test
echo -e "\nStart netserver..."
start_server_on_local

echo -e "\nStart netperf test..."
load_test_from_peers 1400
echo -e "Receive test:\n" >> $logfile
cat $debuglog >> $logfile
echo -e "Source data:\n" >> $logfile
cat $sdatalog >> $logfile
rm -f $debuglog $sdatalog
BWrx=$bw

echo -e "\nStart netperf test..."
load_test_from_peers 1
echo -e "Receive test:\n" >> $logfile
cat $debuglog >> $logfile
echo -e "Source data:\n" >> $logfile
cat $sdatalog >> $logfile
rm -f $debuglog $sdatalog
PPSrx=$pps

echo -e "\nStop netserver..."
stop_server_on_local

# Write down summary
echo -e "\nTest Summary: \n----------\n" >> $logfile
printf "** %-20s %-10s %-10s %-10s %-10s\n" VMSize "BWtx(Gb/s)" PPStx "BWrx(Gb/s)" PPSrx >> $logfile
printf "** %-20s %-10s %-10s %-10s %-10s\n" $vmsize $BWtx $PPStx $BWrx $PPSrx >> $logfile

tail -n 4 $logfile

exit 0
