ip netns exec clab-esilab-server2 ip addr add 198.18.100.102/24 dev eth1
ip netns exec clab-esilab-server2 ip route add 198.18.0.0/16 via 198.18.100.254
ip netns exec clab-esilab-server3 ip addr add 198.18.100.103/24 dev eth1
ip netns exec clab-esilab-server3 ip route add 198.18.0.0/16 via 198.18.100.254
ip netns exec clab-esilab-server4 ip addr add 198.18.200.201/24 dev eth1
ip netns exec clab-esilab-server4 ip route add 198.18.0.0/16 via 198.18.200.254
ip netns exec clab-esilab-server5 ip addr add 198.18.100.105/24 dev eth1
ip netns exec clab-esilab-server5 ip route add 198.18.0.0/16 via 198.18.100.254
