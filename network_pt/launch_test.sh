
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

	#region="us-west-1"
	#sgid="sg-rj9f46qhpa7q02u5jl2p"
	#imageid="rhel_6_9_64_20G_alibaba_20171117.vhd"		# rhel6.9-1117
	#imageid="rhel_7_4_64_20G_alibase_201701102.vhd"	# rhel7.4-1102
	#imageid="rhel_7_4_64_20G_alibaba_20171117.vhd"		# rhel7.4-1117
	#imageid="alinux_7_01_64_40G_base_20170310.vhd"		# alinux7.01
	#vswid="vsw-rj9vsve1fki07cy99plex"	# us-west-1a
	#vswid="vsw-rj9mxj81k24a3erwqibza"	# us-west-1b

	#region="cn-beijing"
	#sgid="sg-2zegq49eb2h96hflufnr"
	#imageid="m-2ze3kh9x3c6cxyqop18l"	# rhel7.4
	#vswid="vsw-2zegaxvc42lxgix28cmat"	# cn-beijing-c
	#vswid="vsw-2ze52osdol5jxuo96pv9f"	# cn-beijing-e

	#region="cn-qingdao"
	#sgid="sg-m5ej0zywmf2jtdlbw3bb"
	#imageid="m-m5ebpt5n7u6mwj45e13i"		# rhel7.4
	#imageid="alinux_7_01_64_40G_base_20170310.vhd"	# alinux7.01
	#vswid="vsw-m5edmrxkpghe3xh5w8rvm"		# cn-qingdao-c

	region="cn-hangzhou"
	sgid="sg-bp11wy2vjnk28zxk8j2r"
	imageid="rhel_7_4_64_20G_alibaba_20171117.vhd"	# rhel7.4
	vswid="vsw-bp19x809038ogmhja9m9u"		# cn-hangzhou-b
	vswid=""		# cn-hangzhou-f


	# create instance
	echo "aliyuncli ecs CreateInstance --InstanceType $instance_type --RegionID $region --ImageId $imageid --InternetChargeType PayByBandwidth --SecurityGroupId $sgid --IoOptimized optimized --InternetMaxBandwidthOut 5 --SystemDiskCategory cloud_efficiency --KeyPairName cheshi --VSwitchId $vswid --InstanceName $instance_name --HostName $host_name"
	x=$(aliyuncli ecs CreateInstance --InstanceType $instance_type --RegionID $region --ImageId $imageid --InternetChargeType PayByBandwidth --SecurityGroupId $sgid --IoOptimized optimized --InternetMaxBandwidthOut 5 --SystemDiskCategory cloud_efficiency --KeyPairName cheshi --VSwitchId $vswid --InstanceName $instance_name --HostName $host_name) # --ZoneId $zoneid)
	if [ $? -eq 0 ]; then
		instance_id=$(echo $x | jq -r .InstanceId)
		echo "Instance created, resource id = $instance_id"
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
	create_instance ecs.sn2ne.2xlarge cheshi-netpt-test-machine ecs.sn2ne.2xlarge
	create_instance ecs.sn2ne.xlarge cheshi-netpt-train-machine-1 cheshi-netpt-peer-1
	create_instance ecs.sn2ne.xlarge cheshi-netpt-train-machine-2 cheshi-netpt-peer-2
}


function create_test_machines()
{
	instance_type=${1:-"ecs.sn2ne.14xlarge"}
	create_instance $instance_type cheshi-netpt-test-machine $instance_type
}


function create_train_machines()
{
	instance_type=${1:-"ecs.sn2ne.2xlarge"}

	for i in {1..24}; do
		create_instance $instance_type cheshi-netpt-train-machine-$i cheshi-netpt-peer-$i
	done
}


function delete_instance()
{
	[ -z "$1" ] && return 1

	if [[ "$1" = i-* ]]; then
		instance_id=$1
	else
		instance_name=$1
		instance_id=$(aliyuncli ecs DescribeInstances --InstanceName $instance_name | jq -r .Instances.Instance[].InstanceId)
	fi

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
	for i in {1..24}; do
		show_instance_info cheshi-netpt-train-machine-$i	# &>/dev/null
		[ -z "$private_ip" ] && continue
		[ -z "$private_ips" ] && private_ips=$private_ip || private_ips="$private_ips $private_ip"
	done

	echo -e "List of private_ips for train machine:\n\"$private_ips\""
}



function main()
{
	#create_cluster
	#create_train_machines ecs.sn2ne.xlarge
	#create_test_machines ecs.sn2ne.14xlarge

	show_instance_info cheshi-netpt-test-machine
	#show_instance_info cheshi-netpt-train-machine-1
	#show_instance_info cheshi-netpt-train-machine-2

	list_private_ips

	exit 0
}

#main
