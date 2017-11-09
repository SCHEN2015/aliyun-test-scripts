#!/bin/bash

# This script is used in VM

type iperf3 && echo "Already installed." && exit 0

curl -O https://iperf.fr/download/fedora/iperf3-3.1.3-1.fc24.x86_64.rpm
sudo rpm -ivh iperf3-3.1.3-1.fc24.x86_64.rpm

iperf3 -h

exit 0

