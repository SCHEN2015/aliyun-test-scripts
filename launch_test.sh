
function show_instance_info()
{
	[ "$1" = "" ] && return 1 || instance_name=$1
	x=$(aliyuncli ecs DescribeInstances --InstanceName $instance_name)
	if [ $? -eq 0 ]; then
		instance_name=$(echo $x | jq -r .Instances.Instance[].InstanceName)
		instance_id=$(echo $x | jq -r .Instances.Instance[].InstanceId)
		host_name=$(echo $x | jq -r .Instances.Instance[].HostName)
		private_ip=$(echo $x | jq -r .Instances.Instance[].VpcAttributes.PrivateIpAddress.IpAddress[])
		public_ip=$(echo $x | jq -r .Instances.Instance[].PublicIpAddress.IpAddress[])
		instance_status=$(echo $x | jq -r .Instances.Instance[].Status)
	else
		instance_name=""
		instance_id=""
		host_name=""
		private_ip=""
		public_ip=""
		instance_status=""
	fi

	# show information
	echo "--------------------"
	echo "instance_name:   $instance_name"
	echo "instance_id:     $instance_id"
	echo "host_name:       $host_name"
	echo "private_ip:      $private_ip"
	echo "public_ip:       $public_ip"
	echo "instance_status: $instance_status"
	echo "--------------------"
}


function create_instance()
{
	# $1: Instance Type
	# $2: Instance Name
	# $3: Host Name

	instance_type=$1
	instance_name=$2
	host_name=$3

	echo -e "\nCreate Instance: $@"

	# create instance
	x=$(aliyuncli ecs CreateInstance --InstanceType $instance_type --region us-west-1 --ImageId rhel_7_4_64_20G_alibase_201701102.vhd --InternetChargeType PayByBandwidth --SecurityGroupId sg-rj9f46qhpa7q02u5jl2p --IoOptimized optimized --InternetMaxBandwidthOut 5 --SystemDiskCategory cloud_efficiency --KeyPairName cheshi --VSwitchId vsw-rj9mxj81k24a3erwqibza --InstanceName $instance_name --HostName $host_name)
	if [ $? -eq 0 ]; then
		instance_id=$(echo $x | jq -r .InstanceId)
		echo "Instance created, resource id = $instance_id)"
	else
		echo "$x"
		echo "aliyuncli ecs CreateInstance failed."
		return 1
	fi

	# wait the instance
	echo "Waiting for 20s..."
	sleep 20s

	# assign public ip
	x=$(aliyuncli ecs AllocatePublicIpAddress --InstanceId $instance_id)
	if [ $? -eq 0 ]; then
		echo "PublicIpAddress Allocated."
	else
		echo "$x"
		echo "aliyuncli ecs AllocatePublicIpAddress failed."
		return 1
	fi

	# start instance
	x=$(aliyuncli ecs StartInstance --InstanceId $instance_id)
	if [ $? -eq 0 ]; then
		echo "Instance Started."
	else
		echo "$x"
		echo "aliyuncli ecs StartInstance failed."
		return 1
	fi
}


function create_cluster()
{
	#timestamp=$(date -u +%Y%m%d%H%M%S)

	# test machine
	create_instance ecs.sn1ne.xlarge cheshi-netpt-test-machine cheshi-netpt-test
	create_instance ecs.sn1ne.large cheshi-netpt-train-machine-1 cheshi-netpt-train-1
	create_instance ecs.sn1ne.large cheshi-netpt-train-machine-2 cheshi-netpt-train-2
}


function create_test_machines()
{
	instance_type=${1:-"ecs.sn2ne.14xlarge"}
	create_instance $instance_type cheshi-netpt-test-machine $instance_type
}


function create_train_machines()
{
	instance_type=${1:-"ecs.sn2ne.2xlarge"}

	for i in $(seq 8); do
		create_instance $instance_type cheshi-netpt-train-machine-$i cheshi-netpt-peer-$i
	done
}


function delete_instance()
{
	[ -z "$1" ] && return 1 || instance_id=$1

	x=$(aliyuncli ecs StopInstance --InstanceId $instance_id)
	if [ $? -eq 0 ]; then
		echo "Instance Stopped."
	else
		echo "$x"
		echo "aliyuncli ecs StopInstance failed."
		return 1
	fi

	sleep 10s

	x=$(aliyuncli ecs DeleteInstance --InstanceId $instance_id --Force)
	if [ $? -eq 0 ]; then
		echo "Instance Deleted."
	else
		echo "$x"
		echo "aliyuncli ecs DeleteInstance failed."
		return 1
	fi
}


function list_private_ips()
{
	private_ips=""
	for i in $(seq 8); do
		show_instance_info cheshi-netpt-train-machine-$i	# &>/dev/null
		[ -z "$private_ips" ] && private_ips=$private_ip || private_ips="$private_ips $private_ip"
	done

	echo -e "List of private_ips for train machine:\n\"$private_ips\""
}

#create_cluster
#create_train_machines
#create_test_machines ecs.sn2ne.14xlarge

#show_instance_info cheshi-netpt-test-machine
#show_instance_info cheshi-netpt-train-machine-1
#show_instance_info cheshi-netpt-train-machine-2

list_private_ips

exit 0

