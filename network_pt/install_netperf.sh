#!/bin/bash

# This script is used in VM

type netperf && echo "Already installed." && exit 0

curl -O https://codeload.github.com/HewlettPackard/netperf/tar.gz/netperf-2.5.0
mv netperf-2.5.0 netperf-2.5.0.tar.gz
tar -zxvf netperf-2.5.0.tar.gz
cd netperf-netperf-2.5.0
./configure && make && make install && cd ..

netperf -h
netserver -h 

exit 0

