#!/bin/bash

# Running on your PC.

# get functions in other script
source ./launch_test.sh

# Global parameters
instance_type=${1:-"ecs.sn2ne.8xlarge"}
peerips="172.20.215.0 172.20.215.1 172.20.215.2 172.20.215.3 172.20.215.4 172.20.215.5 172.20.215.6 172.20.215.7 172.20.215.8 172.20.215.9 172.20.215.10 172.20.215.11 172.20.215.12 172.20.215.13 172.20.215.14 172.20.215.15"

# Launch instance
timestamp=$(date -u +%Y%m%d%H%M%S)
tm_instance_name="cheshi-netpt-test-machine-$timestamp"

create_instance $instance_type ${tm_instance_name:="cheshi-netpt-test-machine"} $instance_type

# Waiting instance become Running
instance_status="Starting"
while [ "$instance_status" = "Starting" ]; do
    sleep 5s
    show_instance_info $tm_instance_name &>/dev/null
    echo "Instance $instance_name status: $instance_status"
done

# Get Public IP
if [ "$instance_status" = "Running" ]; then
    testip=$public_ip
    echo "Public IP: $public_ip"
else
    echo "Error! Launch instance failed!!!"
    exit 1
fi

echo "Waiting 2 min..."
sleep 2m

# Prepare test machine
ssh-keygen -q -R $testip
ssh -o StrictHostKeyChecking=no root@$testip "hostname"
scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa root@$testip:~/cheshi_aliyun.pem
if [ $? -ne 0 ]; then
    echo "This IP may be blocked by GFW."
    delete_instance $tm_instance_name
    exit 1
fi
scp *.sh *.txt root@$testip:~

# Setup environment
ssh root@$testip "~/setup_environment.sh 127.0.0.1 \"$peerips\""

# Run test
ssh root@$testip "~/netperf_test.sh \"$peerips\""
ssh root@$testip "~/netperf_test.sh \"$peerips\""
ssh root@$testip "~/netperf_test.sh \"$peerips\""
#ssh root@$testip "~/netperf_test.sh \"$peerips $peerips\""

# Get log
scp root@$testip:~/netperf_test_*.log .

# Delete instance
delete_instance $tm_instance_name

exit 0
