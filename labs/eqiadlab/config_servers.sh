#!/bin/bash
set -x
sudo ip netns exec clab-eqiadlab-server1 ip addr add 198.18.100.11/24 dev eth1
sudo ip netns exec clab-eqiadlab-server1 ip route add 198.18.0.0/16 via 198.18.100.254
sudo ip netns exec clab-eqiadlab-server1 ip addr add 2001:0470:6a7f:0100::11/64 dev eth1
sudo ip netns exec clab-eqiadlab-server1 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254

sudo ip netns exec clab-eqiadlab-server2 ip addr add 198.18.100.12/24 dev eth1
sudo ip netns exec clab-eqiadlab-server2 ip route add 198.18.0.0/16 via 198.18.100.254
sudo ip netns exec clab-eqiadlab-server2 ip addr add 2001:0470:6a7f:0100::12/64 dev eth1
sudo ip netns exec clab-eqiadlab-server2 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254

sudo ip netns exec clab-eqiadlab-server3 ip addr add 198.18.101.13/24 dev eth1
sudo ip netns exec clab-eqiadlab-server3 ip route add 198.18.0.0/16 via 198.18.101.254
sudo ip netns exec clab-eqiadlab-server3 ip addr add 2001:0470:6a7f:0101::13/64 dev eth1
sudo ip netns exec clab-eqiadlab-server3 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0101::254

