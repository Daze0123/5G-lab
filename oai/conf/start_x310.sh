#!/bin/bash

echo "Disabling CPU C-States for DPDK..."
sudo cpupower idle-set -D 0

echo "Binding NIC to vfio-pci..."
# Ensure 0000:02:00.1 matches the exact PCI address of enp2s0f1np1
sudo dpdk-devbind.py -b vfio-pci 0000:02:00.1 

echo "Launching OAI..."
sudo taskset -c 0-11 chrt -f 99 ./nr-softmodem -O x310_332G.conf --usrp-tx-thread-config 1 --tune-offset 24000000 -E
