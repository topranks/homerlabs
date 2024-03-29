#!/bin/bash
set -x

sudo ip netns exec clab-codfw_migrate-server1 ip route del default
sudo ip netns exec clab-codfw_migrate-server1 ip -6 route del default
sudo ip netns exec clab-codfw_migrate-server1 ip addr add 10.192.0.11/22 dev eth1
sudo ip netns exec clab-codfw_migrate-server1 ip route add default via 10.192.0.1
sudo ip netns exec clab-codfw_migrate-server1 ip addr add 2620:0:860:101::11/64 dev eth1
#sudo ip netns exec clab-codfw_migrate-server1 ip -6 route add default via 2620:0:860:101::1

sudo ip netns exec clab-codfw_migrate-server2 ip route del default
sudo ip netns exec clab-codfw_migrate-server2 ip -6 route del default
sudo ip netns exec clab-codfw_migrate-server2 ip addr add 10.192.0.12/22 dev eth1
sudo ip netns exec clab-codfw_migrate-server2 ip route add default via 10.192.0.1
sudo ip netns exec clab-codfw_migrate-server2 ip addr add 2620:0:860:101::12/64 dev eth1
#sudo ip netns exec clab-codfw_migrate-server2 ip -6 route add default via 2620:0:860:101::1

sudo ip netns exec clab-codfw_migrate-server1_b ip route del default
sudo ip netns exec clab-codfw_migrate-server1_b ip -6 route del default
sudo ip netns exec clab-codfw_migrate-server1_b ip -6 addr flush dev eth1
sudo ip netns exec clab-codfw_migrate-server1_b ip link add link eth1 name eth1.100 type vlan id 100
sudo ip netns exec clab-codfw_migrate-server1_b ip addr add 10.192.0.13/22 dev eth1.100
sudo ip netns exec clab-codfw_migrate-server1_b ip link set dev eth1.100 up
sudo ip netns exec clab-codfw_migrate-server1_b ip route add default via 10.192.0.1
sudo ip netns exec clab-codfw_migrate-server1_b ip link add link eth1 name eth1.200 type vlan id 200
sudo ip netns exec clab-codfw_migrate-server1_b ip addr add 192.168.187.13/24 dev eth1.200
sudo ip netns exec clab-codfw_migrate-server1_b ip link set dev eth1.200 up 

sudo ip netns exec clab-codfw_migrate-server2_b ip route del default
sudo ip netns exec clab-codfw_migrate-server2_b ip -6 route del default
sudo ip netns exec clab-codfw_migrate-server2_b ip addr add 10.192.0.14/22 dev eth1
sudo ip netns exec clab-codfw_migrate-server2_b ip route add default via 10.192.0.1
sudo ip netns exec clab-codfw_migrate-server2_b ip addr add 2620:0:860:101::14/64 dev eth1

#sudo ip netns exec clab-codfw_migrate-server1_b ip -6 route add default via 2620:0:860:101::1

sudo ip netns exec clab-codfw_migrate-remote1 ip route del default
sudo ip netns exec clab-codfw_migrate-remote1 ip -6 route del default
sudo ip netns exec clab-codfw_migrate-remote1 ip addr add 100.64.100.5/31 dev eth1
sudo ip netns exec clab-codfw_migrate-remote1 ip route add default via 100.64.100.4
sudo ip netns exec clab-codfw_migrate-remote1 ip addr add 2620:0:860:3:fe00::2/64 dev eth1
sudo ip netns exec clab-codfw_migrate-remote1 ip -6 route add default via 2620:0:860:3:fe00::1

sudo ip netns exec clab-codfw_migrate-remote2 ip route del default
sudo ip netns exec clab-codfw_migrate-remote2 ip -6 route del default
sudo ip netns exec clab-codfw_migrate-remote2 ip addr add 100.64.100.7/31 dev eth1
sudo ip netns exec clab-codfw_migrate-remote2 ip route add default via 100.64.100.6
sudo ip netns exec clab-codfw_migrate-remote2 ip addr add 2620:0:860:4:fe00::2/64 dev eth1
sudo ip netns exec clab-codfw_migrate-remote2 ip -6 route add default via 2620:0:860:4:fe00::1 


