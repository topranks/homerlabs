# eqiadlab

![eqiadlab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/eqiadlab/diagram.png)

This is a containerlab topology based on my previous [evpnlab](../evpnlab), but with two vMX devices added to simulate core/border routers.

Running the lab is similar to evpnlab so no need to go into detail here:

#### Running the lab

Users should have installed everything as described in [getting started](../../getting_started.md), and be familiar with the generic steps described there to run labs.  Below is a high-level overview:

##### 1. Change to the lab directory and init the lab with containerlab:
```
cd ~/homerlabs/labs/eqiadlab
sudo clab deploy -t eqiadlab.yaml
```

vQFX devices take a few minutes to start up, so wait 5-10 minutes before proceeding.

##### 2. Add entries for lab nodes to your local host file:
```
cd ~/homerlabs
sudo ./add_fqdn_hosts.py
```

##### 3. Add local user and SSH key to the vQFX devices:
```
sudo ./add_junos_user.py --user homer --pubkey ~/.ssh/homerlabs_ed25519.pub 
```

##### 4. Configure the vQFX devices with Homer:
```
homer '*' commit "configure eqiadlab"
```

##### 5. Configure server container IP addressing

Run the `config_servers.sh` shell script from the lab dir to add basic IP configuration to the containers simulating end servers:
```
cathal@officepc:~/homerlabs/labs/eqiadlab$ ./config_servers.sh 
+ sudo ip netns exec clab-eqiadlab-server1 ip addr add 198.18.100.11/24 dev eth1
+ sudo ip netns exec clab-eqiadlab-server1 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-eqiadlab-server1 ip addr add 2001:0470:6a7f:0100::11/64 dev eth1
+ sudo ip netns exec clab-eqiadlab-server1 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254
+ sudo ip netns exec clab-eqiadlab-server2 ip addr add 198.18.100.12/24 dev eth1
+ sudo ip netns exec clab-eqiadlab-server2 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-eqiadlab-server2 ip addr add 2001:0470:6a7f:0100::12/64 dev eth1
+ sudo ip netns exec clab-eqiadlab-server2 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254
+ sudo ip netns exec clab-eqiadlab-server3 ip addr add 198.18.101.13/24 dev eth1
+ sudo ip netns exec clab-eqiadlab-server3 ip route add 198.18.0.0/16 via 198.18.101.254
+ sudo ip netns exec clab-eqiadlab-server3 ip addr add 2001:0470:6a7f:0101::13/64 dev eth1
+ sudo ip netns exec clab-eqiadlab-server3 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0101::254
```
