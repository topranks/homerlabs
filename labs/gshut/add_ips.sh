#!/bin/bash
set -x

sudo ip netns exec clab-gshut-r1 ip addr add 198.18.0.0/31 dev eth1
sudo ip netns exec clab-gshut-r2 ip addr add 198.18.0.1/31 dev eth1

sudo ip netns exec clab-gshut-r1 ip addr add 198.18.0.2/31 dev eth2
sudo ip netns exec clab-gshut-r3 ip addr add 198.18.0.3/31 dev eth1

sudo ip netns exec clab-gshut-r2 ip addr add 198.18.0.4/31 dev eth2
sudo ip netns exec clab-gshut-r3 ip addr add 198.18.0.5/31 dev eth2

sudo ip netns exec clab-gshut-r4 ip addr add 198.18.0.6/31 dev eth1
sudo ip netns exec clab-gshut-r2 ip addr add 198.18.0.7/31 dev eth3

sudo ip netns exec clab-gshut-r4 ip addr add 198.18.0.8/31 dev eth2
sudo ip netns exec clab-gshut-r3 ip addr add 198.18.0.9/31 dev eth3

