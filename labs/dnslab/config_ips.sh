#!/bin/bash
set -x
# Loopbacks
ip netns exec clab-dnslab-core1 ip addr add 100.64.0.1/32 dev lo
ip netns exec clab-dnslab-core2 ip addr add 100.64.0.2/32 dev lo
ip netns exec clab-dnslab-spine1 ip addr add 1.1.1.1/32 dev lo
ip netns exec clab-dnslab-spine2 ip addr add 2.2.2.2/32 dev lo
ip netns exec clab-dnslab-leaf1 ip addr add 11.11.11.11/32 dev lo
ip netns exec clab-dnslab-leaf2 ip addr add 12.12.12.12/32 dev lo
ip netns exec clab-dnslab-leaf3 ip addr add 13.13.13.13/32 dev lo

# /31 routed links
ip netns exec clab-dnslab-spine1 ip addr add 10.1.1.0/31 dev eth1
ip netns exec clab-dnslab-leaf1 ip addr add 10.1.1.1/31 dev eth1
ip netns exec clab-dnslab-spine1 ip addr add 10.2.1.0/31 dev eth2
ip netns exec clab-dnslab-leaf2 ip addr add 10.2.1.1/31 dev eth1
ip netns exec clab-dnslab-spine1 ip addr add 10.3.1.0/31 dev eth3
ip netns exec clab-dnslab-leaf3 ip addr add 10.3.1.1/31 dev eth1
ip netns exec clab-dnslab-spine2 ip addr add 10.1.2.0/31 dev eth1
ip netns exec clab-dnslab-leaf1 ip addr add 10.1.2.1/31 dev eth2
ip netns exec clab-dnslab-spine2 ip addr add 10.2.2.0/31 dev eth2
ip netns exec clab-dnslab-leaf2 ip addr add 10.2.2.1/31 dev eth2
ip netns exec clab-dnslab-spine2 ip addr add 10.3.2.0/31 dev eth3
ip netns exec clab-dnslab-leaf3 ip addr add 10.3.2.1/31 dev eth2
ip netns exec clab-dnslab-leaf1 ip addr add 10.10.1.0/31 dev eth3
ip netns exec clab-dnslab-server1 ip addr add 10.10.1.1/31 dev eth1
ip netns exec clab-dnslab-leaf2 ip addr add 10.10.2.0/31 dev eth3
ip netns exec clab-dnslab-server2 ip addr add 10.10.2.1/31 dev eth1
ip netns exec clab-dnslab-spine1 ip addr add 10.20.1.0/31 dev eth4
ip netns exec clab-dnslab-core1 ip addr add 10.20.1.1/31 dev eth2
ip netns exec clab-dnslab-spine2 ip addr add 10.20.2.0/31 dev eth4
ip netns exec clab-dnslab-core2 ip addr add 10.20.2.1/31 dev eth2

# asw bridge
ip netns exec clab-dnslab-asw1 ip link add name br0 type bridge
ip netns exec clab-dnslab-asw1 ip link set dev eth1 master br0
ip netns exec clab-dnslab-asw1 ip link set dev eth2 master br0
ip netns exec clab-dnslab-asw1 ip link set dev eth3 master br0
ip netns exec clab-dnslab-asw1 ip link set dev br0 up

# asw endpoints
ip netns exec clab-dnslab-core1 ip addr add 100.64.0.2/22 dev eth3
ip netns exec clab-dnslab-core2 ip addr add 100.64.0.3/22 dev eth3
ip netns exec clab-dnslab-server3 ip addr add 100.64.0.10/22 dev eth1

# server anycast IP
ip netns exec clab-dnslab-server1 ip addr add 192.0.2.1/32 dev lo
ip netns exec clab-dnslab-server2 ip addr add 192.0.2.1/32 dev lo
ip netns exec clab-dnslab-server3 ip addr add 192.0.2.1/32 dev lo

