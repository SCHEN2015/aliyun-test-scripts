#!/bin/bash

# This script is used in VM

wget -c "https://codeload.github.com/HewlettPackard/netperf/tar.gz/netperf-2.5.0" -O netperf-2.5.0.tar.gz
tar -zxvf netperf-2.5.0.tar.gz
cd netperf-netperf-2.5.0
./configure && make && make install && cd ..

netperf -h
netserver -h 

exit 0

