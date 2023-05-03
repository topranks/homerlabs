#!/bin/bash
set -x
sudo ip netns exec clab-filterlab-tata ip addr add 80.231.152.77/30 dev eth1

sudo ip netns exec clab-filterlab-r1 ip addr add 80.231.152.78/30 dev eth1

sudo ip netns exec clab-filterlab-r1 ip link add link eth2 name eth2.100 type vlan id 100
sudo ip netns exec clab-filterlab-r1 ip link add link eth2 name eth2.101 type vlan id 101
sudo ip netns exec clab-filterlab-r1 ip link set dev eth2.100 up
sudo ip netns exec clab-filterlab-r1 ip link set dev eth2.101 up
sudo ip netns exec clab-filterlab-r1 ip addr flush dev eth2
sudo ip netns exec clab-filterlab-r1 ip addr add 2.57.56.1/24 dev eth2.100
sudo ip netns exec clab-filterlab-r1 ip addr add 5.157.80.1/24 dev eth2.101

sudo ip netns exec clab-filterlab-server1 ip link add link eth1 name eth1.100 type vlan id 100
sudo ip netns exec clab-filterlab-server1 ip link add link eth1 name eth1.101 type vlan id 101
sudo ip netns exec clab-filterlab-server1 ip link set dev eth1.100 up
sudo ip netns exec clab-filterlab-server1 ip link set dev eth1.101 up
sudo ip netns exec clab-filterlab-server1 ip addr flush dev eth1
sudo ip netns exec clab-filterlab-server1 ip addr add 2.57.56.2/24 dev eth1.100
sudo ip netns exec clab-filterlab-server1 ip addr add 5.187.80.2/24 dev eth1.101
