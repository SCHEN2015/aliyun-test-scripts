#!/bin/bash

# This script run on test host.
# Inputs: an ip list of peer hosts


function start_server_on_peers()
{
	n=0
	for host in $peer_host_list; do
		[ $n -eq ${maxlink:=-1} ] && break
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
		[ $n -eq ${maxlink:=-1} ] && break
		let n=n+1
		echo "Stop netserver on peer $host."
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "pidof netserver | xargs kill -9 &>/dev/null"
	done
}

function load_test_to_peers()
{
	# Inputs : $1 = message size;
	# Outputs: $debuglog; $sdatalog; $bw : bandwidth in Mb/s; $pps : package# per second
	msize=${1:-1400}

	# trigger load test
	n=0
	for host in $peer_host_list; do
		[ $n -eq ${maxlink:=-1} ] && break
		let n=n+1
		let port=10080+n
		tmplog=./netperf.tmplog.$n
		echo "Start netperf test at port $port to host $host"
		netperf -H $host -p $port -t UDP_STREAM -l ${duration:=10} -f m -- -m $msize &> $tmplog &
	done

	wait

	# get results
	debuglog=./debuginfo.log
	sdatalog=./sourcedata.log

	rm -f $debuglog &>/dev/null
	rm -f $sdatalog &>/dev/null

	for tmplog in $(ls ./netperf.tmplog.*); do
		sed -n '6p' $tmplog >> $sdatalog	# Get the 1st line of UDP_STREAM report (local:test-machine)
		cat $tmplog >> $debuglog
		rm -f $tmplog
	done

	# Calculated from the 1st line of UDP_STREAM report (local:test-machine)
	bw=$(cat $sdatalog | awk '{SUM += $6};END {print SUM / 1000}')
	pps=$(cat $sdatalog | awk '{SUM += $4 / $3};END {print SUM / 10000}')
}

function start_server_on_local()
{
	n=0
	for host in $peer_host_list; do
		[ $n -eq ${maxlink:=-1} ] && break
		let n=n+1
		let port=10080+n
		echo "Start netserver on localhost, listen at $port."
		netserver -p $port
	done
}

function stop_server_on_local()
{
	echo "Stop netserver on localhost."
	pidof netserver | xargs kill -9 &>/dev/null
}

function load_test_from_peers()
{
	# Inputs : $1 = message size;
	# Outputs: $debuglog; $sdatalog; $bw : bandwidth in Mb/s; $pps : package# per second
	msize=${1:-1400}

	localip=$(ifconfig eth0 | grep -w inet | awk '{print $2}')
	[[ "$localip" = addr* ]] && localip=$(echo $localip | cut -f2 -d:)	# bugfix for RHEL6

	# trigger load test
	n=0
	for host in $peer_host_list; do
		[ $n -eq ${maxlink:=-1} ] && break
		let n=n+1
		let port=10080+n
		echo "Start netperf test at port $port from host $host"
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "netperf -H $localip -p $port -t UDP_STREAM -l ${duration:=10} -f m -- -m $msize &> ~/temp.log.$port" &
	done

	wait

	# get remote logs
	n=0
	for host in $peer_host_list; do
		[ $n -eq ${maxlink:=-1} ] && break
		let n=n+1
		let port=10080+n
		tmplog=./netperf.tmplog.$port
		ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "cat ~/temp.log.$port; rm -f ~/temp.log.$port" &> $tmplog &
	done

	wait

	# get results
	debuglog=./debuginfo.log
	sdatalog=./sourcedata.log

	rm -f $debuglog &>/dev/null
	rm -f $sdatalog &>/dev/null
	
	for tmplog in $(ls ./netperf.tmplog.*); do
		sed -n '7p' $tmplog >> $sdatalog	# Get the 2nd line of UDP_STREAM report (remote:test-machine)
		cat $tmplog >> $debuglog
		rm -f $tmplog
	done

	# Calculated from the 2nd line of UDP_STREAM report (remote:test-machine)
	bw=$(cat $sdatalog | awk '{SUM += $4};END {print SUM / 1000}')
	pps=$(cat $sdatalog | awk '{SUM += $3 / $2};END {print SUM / 10000}')
}


# main
pem=~/cheshi_aliyun.pem
[ -z "$1" ] && echo "Usage: $0 <Peer's IP list>" && exit 1
peer_host_list=$1
vmsize="$(hostname)"	# Can't found instance_type in metadata, so I provisioned the instance_type into hostname.
logfile=./netperf_test_${vmsize}_$(date -u +%Y%m%d%H%M%S).log

nicqn=$(ethtool -l eth0 | grep "Combined:" | tail -n 1 | awk '{print $2}')
let maxlink=$nicqn*2	# comment this line to disable this feature

duration=30

# basic information
./show_info_aliyun.sh >> $logfile
echo -e "\n==========\\n" >> $logfile

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
echo -e "\nReceive test:\n" >> $logfile
cat $debuglog >> $logfile
echo -e "\nSource data:\n" >> $logfile
cat $sdatalog >> $logfile
rm -f $debuglog $sdatalog
BWrx=$bw

echo -e "\nStart netperf test..."
load_test_from_peers 1
echo -e "\nReceive test:\n" >> $logfile
cat $debuglog >> $logfile
echo -e "\nSource data:\n" >> $logfile
cat $sdatalog >> $logfile
rm -f $debuglog $sdatalog
PPSrx=$pps

echo -e "\nStop netserver..."
stop_server_on_local

# Get other information
link=$n

# Write down summary
echo -e "\nTest Summary: \n----------\n" >> $logfile
printf "** %-20s %-5s %-8s %-10s %-10s %-10s %-10s %-6s\n" VMSize Link Duration "BWtx(Gb/s)" "PPStx(10k)" "BWrx(Gb/s)" "PPSrx(10k)" "NICqn">> $logfile
printf "** %-20s %-5s %-8s %-10s %-10s %-10s %-10s %-6s\n" $vmsize $link $duration $BWtx $PPStx $BWrx $PPSrx $nicqn >> $logfile

tail -n 4 $logfile

exit 0
