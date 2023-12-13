#!/bin/bash
set -x


# Base system - should only need to be done once

# sudo ip6tables -I FORWARD 1 -i clab -o enp5s0 -j ACCEPT 
# sudo ip6tables -I FORWARD 1 -o clab -i enp5s0 -j ACCEPT 
# sudo ip addr add 2001:bb6:8b53:a840::1/64 dev clab
# sudo ip route add 2001:bb6:8b53:a842::1/128 via 2001:bb6:8b53:a840::2 
## sysctls for ipv6 forwarding if needed

# Server 1

sudo docker exec clab-onlinklab-server1 sh -c "echo 3 > /proc/sys/net/ipv4/conf/eth1/arp_ignore"
sudo docker exec clab-onlinklab-server1 iptables -t nat -A POSTROUTING -o eth0 -s 2.2.2.2/32 -j MASQUERADE
sudo ip netns exec clab-onlinklab-server1 ip addr add 1.1.1.1/32 dev eth1 scope link 
sudo ip netns exec clab-onlinklab-server1 ip route add 2.2.2.2 dev eth1 scope link 
sudo ip netns exec clab-onlinklab-server1 ip -6 addr flush dev eth0
sudo ip netns exec clab-onlinklab-server1 ip addr add 2001:bb6:8b53:a840::2/64 dev eth0
sudo ip netns exec clab-onlinklab-server1 ip -6 route del default 
sudo ip netns exec clab-onlinklab-server1 ip -6 route add default via 2001:bb6:8b53:a840::1
sudo docker exec clab-onlinklab-server1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/forwarding"
sudo docker exec clab-onlinklab-server1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"
sudo docker exec clab-onlinklab-server1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/eth0/forwarding"
sudo docker exec clab-onlinklab-server1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/eth1/forwarding"
sudo ip netns exec clab-onlinklab-server1 ip addr add 2001:0bb6:8b53:a841::1/128 dev eth1 scope link 
sudo ip netns exec clab-onlinklab-server1 ip route add 2001:0bb6:8b53:a842::1/128 dev eth1 scope link

# Server 2

sudo docker exec clab-onlinklab-server2 sh -c "echo 3 > /proc/sys/net/ipv4/conf/eth1/arp_ignore"
sudo ip netns exec clab-onlinklab-server2 ip addr add 2.2.2.2/32 dev eth1 scope link
sudo ip netns exec clab-onlinklab-server2 ip route add 1.1.1.1 dev eth1 scope link 
sudo ip netns exec clab-onlinklab-server2 ip route del default
sudo ip netns exec clab-onlinklab-server2 ip route add default via 1.1.1.1
sudo ip netns exec clab-onlinklab-server2 ip addr add 2001:0bb6:8b53:a842::1/128 dev eth1 scope link
sudo ip netns exec clab-onlinklab-server2 ip route add 2001:0bb6:8b53:a841::1/128 dev eth1 scope link 
sudo ip netns exec clab-onlinklab-server2 ip -6 route del default 
sudo ip netns exec clab-onlinklab-server2 ip -6 route add default via 2001:bb6:8b53:a841::1

