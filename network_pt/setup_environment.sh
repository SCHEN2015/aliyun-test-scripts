#!/bin/bash

# This script run on test host.
# Inputs: an ip list of peer hosts


function upload()
{
	host=$1
	echo "Upload scripts to host $host"
	scp -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem \
		install_netperf.sh install_iperf3.sh enable_rps.sh disable_rps.sh check_environment.sh root@$host:~ &>/dev/null &
}

function setup()
{
	host=$1
	echo "Setup environment on host $host"
	ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "~/install_netperf.sh &>/dev/null" &
	#ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "~/install_iperf3.sh &>/dev/null" &
	ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "~/enable_rps.sh &>/dev/null" &
	#ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "~/disable_rps.sh &>/dev/null" &
}

function reboot()
{
	host=$1
	[ "$host" = "127.0.0.1" ] && echo "Skip rebooting 127.0.0.1" && return 0
	echo "Reboot host $host"
	ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "reboot &" &
}

function check()
{
	host=$1
	echo "Check environment on host $host"
	ssh -o UserKnownHostsFile=~/.my_known_hosts -o StrictHostKeyChecking=no -i $pem root@$host "~/check_environment.sh"
}


# main
pem=~/cheshi_aliyun.pem
[ -z "$1" ] && echo "Usage: $0 127.0.0.1 <Peer's IP list>" && exit 1
peer_host_list=$@
logfile=./netperf.full.log
vmsize="Unknown"


for host in $peer_host_list; do
	upload $host
done
wait

for host in $peer_host_list; do
	setup $host
done
wait

#for host in $peer_host_list; do
#	reboot $host
#done
#sleep 1m

for host in $peer_host_list; do
	check $host
done
wait

exit 0
