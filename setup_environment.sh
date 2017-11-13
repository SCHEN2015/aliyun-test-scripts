#!/bin/bash

# This script run on test host.
# Inputs: an ip list of peer hosts


function upload()
{
	host=$1
	echo "Upload scripts to host $host"
	scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $pem install_netperf.sh enable_rps.sh check_environment.sh root@$host:~ &>/dev/null &
}

function setup()
{
	host=$1
	echo "Setup environment on host $host"
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $pem root@$host "~/install_netperf.sh &>/dev/null" &
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $pem root@$host "~/enable_rps.sh &>/dev/null" &
}

function check()
{
	host=$1
	echo "Check environment on host $host"
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $pem root@$host "~/check_environment.sh"
}


# main
pem=~/cheshi_aliyun.pem
peer_host_list=${@:-"172.20.213.194 172.20.213.192"}
logfile=./netperf.full.log
vmsize="Unknown"


for host in $peer_host_list; do
	upload $host
	wait
	setup $host
	wait
	check $host
done

exit 0
