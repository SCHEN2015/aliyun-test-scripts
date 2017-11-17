#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# This script is used to tell the cloud type

grep -i aliyun /etc/cloud/cloud.cfg &>/dev/null
if [ $? -eq 0 ]; then
	echo "aliyun"
	exit 0
fi

if [ "" = "" ]; then
	echo "aws"
else
	echo "azure"
fi

exit 0

