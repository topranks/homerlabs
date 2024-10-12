set -x
### R1
ip netns exec clab-v6_sysctl-r1 ip link add testvrf type vrf table 10
ip netns exec clab-v6_sysctl-r1 ip link set dev testvrf up
ip netns exec clab-v6_sysctl-r1 ip route add vrf testvrf unreachable default metric 4278198272

ip netns exec clab-v6_sysctl-r1 ip link set dev eth1 up
ip netns exec clab-v6_sysctl-r1 ip link set dev eth2 up
ip netns exec clab-v6_sysctl-r1 ip link set dev eth3 master testvrf
ip netns exec clab-v6_sysctl-r1 ip link set dev eth4 master testvrf
ip netns exec clab-v6_sysctl-r1 ip link set dev eth3 up
ip netns exec clab-v6_sysctl-r1 ip link set dev eth4 up

ip netns exec clab-v6_sysctl-r1 sysctl -w net.ipv6.conf.eth1.forwarding=1
ip netns exec clab-v6_sysctl-r1 sysctl -w net.ipv6.conf.eth2.forwarding=1
ip netns exec clab-v6_sysctl-r1 sysctl -w net.ipv6.conf.eth3.forwarding=1
ip netns exec clab-v6_sysctl-r1 sysctl -w net.ipv6.conf.eth4.forwarding=1

ip netns exec clab-v6_sysctl-r1 ip addr add 2001:bb6:8b70:9e71::1/64 dev eth1
ip netns exec clab-v6_sysctl-r1 ip addr add 2001:bb6:8b70:9e72::1/64 dev eth2
ip netns exec clab-v6_sysctl-r1 ip addr add 2001:bb6:8b70:9e73::1/64 dev eth3
ip netns exec clab-v6_sysctl-r1 ip addr add 2001:bb6:8b70:9e74::1/64 dev eth4

### H1
ip netns exec clab-v6_sysctl-h1 ip addr add 2001:bb6:8b70:9e71::2/64 dev eth1
ip netns exec clab-v6_sysctl-h1 ip -6 route add 2001:0bb6:8b70:9e70::/61 via 2001:bb6:8b70:9e71::1

### H2
ip netns exec clab-v6_sysctl-h2 ip addr add 2001:bb6:8b70:9e72::2/64 dev eth1
ip netns exec clab-v6_sysctl-h2 ip -6 route add 2001:0bb6:8b70:9e70::/61 via 2001:bb6:8b70:9e72::1

### H3
ip netns exec clab-v6_sysctl-h3 ip addr add 2001:bb6:8b70:9e73::2/64 dev eth1
ip netns exec clab-v6_sysctl-h3 ip -6 route add 2001:0bb6:8b70:9e70::/61 via 2001:bb6:8b70:9e73::1

### H4
ip netns exec clab-v6_sysctl-h4 ip addr add 2001:bb6:8b70:9e74::2/64 dev eth1
ip netns exec clab-v6_sysctl-h4 ip -6 route add 2001:0bb6:8b70:9e70::/61 via 2001:bb6:8b70:9e74::1

