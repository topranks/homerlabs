# evpnlab

#### Running the lab

Users should have installed everything as described in [getting started](../../getting_started.md), and be familiar with the generic steps described there to run labs.  Below is a high-level overview:

##### 1. Change to the lab directory and init the lab with containerlab:
```
cd ~/homerlabs/labs/evpnlab
sudo clab deploy -t evpnlab.yaml
```

vQFX devices take a few minutes to start up, so wait 5-10 minutes before proceeding.

##### 2. Add entries for lab nodes to your local host file:
```
cd ~/homerlabs
sudo ./add_fqdn_hosts.py
```

##### 3. Add local user and SSH key to the vQFX devices:
```
sudo ./add_junos_user.py --user root --pubkey ~/.ssh/homerlabs_ed25519.pub 
```

##### 4. Configure the cRPD device interfaces

Run the included `config_crpd.py` script to add interface IP addressing to the cRPD nodes
```
cathal@officepc:~/homerlabs/labs/evpnlab$ sudo ./config_crpd.py 
[sudo] password for cathal: 
sudo ip netns exec clab-evpnlab-core2 ip addr add 100.64.0.0/31 dev eth1
sudo ip netns exec clab-evpnlab-core1 ip addr add 100.64.0.1/31 dev eth1
sudo ip netns exec clab-evpnlab-core1 ip addr add 100.64.1.1/31 dev eth2
sudo ip netns exec clab-evpnlab-core2 ip addr add 100.64.2.1/31 dev eth2
```

##### 6. Configure server interface addressing 

Run the `config_servers.sh` shell script from the lab dir to add basic IP configuration to the containers simulating end servers:
```
cathal@officepc:~/homerlabs/labs/evpnlab$ ./config_servers.sh
+ sudo ip netns exec clab-evpnlab-server1 ip addr add 198.18.100.11/24 dev eth1
+ sudo ip netns exec clab-evpnlab-server1 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-evpnlab-server1 ip addr add 2001:0470:6a7f:0100::11/64 dev eth1
+ sudo ip netns exec clab-evpnlab-server1 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254
+ sudo ip netns exec clab-evpnlab-server2 ip addr add 198.18.100.12/24 dev eth1
+ sudo ip netns exec clab-evpnlab-server2 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-evpnlab-server2 ip addr add 2001:0470:6a7f:0100::12/64 dev eth1
+ sudo ip netns exec clab-evpnlab-server2 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254
+ sudo ip netns exec clab-evpnlab-server3 ip addr add 198.18.101.13/24 dev eth1
+ sudo ip netns exec clab-evpnlab-server3 ip route add 198.18.0.0/16 via 198.18.101.254
+ sudo ip netns exec clab-evpnlab-server3 ip addr add 2001:0470:6a7f:0101::13/64 dev eth1
+ sudo ip netns exec clab-evpnlab-server3 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0101::254
```

##### 7. Configure the JunOS devices with Homer:
```
homer '*' commit "configure evpnlab"
```

Type 'yes' to apply the config to each device when prompted.  Once done give it a minute or two and you should see the config is there and protocol adjacencies start coming up.

```
cathal@LEAF1> show ospf neighbor    
Address          Interface              State           ID               Pri  Dead
10.1.1.0         xe-0/0/0.0             Full            1.1.1.1          128    33
10.1.2.0         xe-0/0/1.0             Full            2.2.2.2          128    36
```

Routes learnt in BGP EVPN should be visible in the routing-instance tables:

```
homer@LEAF1> show route table WMF_PROD.inet.0 

WMF_PROD.inet.0: 6 destinations, 8 routes (6 active, 0 holddown, 0 hidden)
@ = Routing Use Only, # = Forwarding Use Only
+ = Active Route, - = Last Active, * = Both

198.18.100.0/24    *[Direct/0] 01:14:00
                    >  via irb.100
                    [EVPN/170] 01:11:36
                    >  to 10.1.1.0 via xe-0/0/0.0
                       to 10.1.2.0 via xe-0/0/1.0
198.18.100.1/32    *[Local/0] 01:14:00
                       Local via irb.100
198.18.100.2/32    *[EVPN/170] 01:11:36
                    >  to 10.1.1.0 via xe-0/0/0.0
                       to 10.1.2.0 via xe-0/0/1.0
198.18.100.254/32  *[Local/0] 01:14:00
                       Local via irb.100
                    [EVPN/170] 01:11:36
                       to 10.1.1.0 via xe-0/0/0.0
                    >  to 10.1.2.0 via xe-0/0/1.0
198.18.200.0/24    *[EVPN/170] 01:11:36
                       to 10.1.1.0 via xe-0/0/0.0
                    >  to 10.1.2.0 via xe-0/0/1.0
198.18.200.254/32  *[EVPN/170] 01:11:36
                    >  to 10.1.1.0 via xe-0/0/0.0
                       to 10.1.2.0 via xe-0/0/1.0
```

##### 5. Checks

Networking should work if all going well!
```
cathal@officepc:~$ docker exec -it clab-evpnlab-server3 bash
root@server3:/# 
root@server3:/# mtr -b -r -c 3 198.18.100.11
Start: 2023-03-21T22:19:22+0000
HOST: server3                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 198.18.101.254             0.0%     3  101.3 134.1 101.3 199.8  56.8
  2.|-- ???                       100.0     3    0.0   0.0   0.0   0.0   0.0
  3.|-- 198.18.100.11              0.0%     3  261.3 256.3 106.4 401.3 147.5
```
```
root@server3:/# mtr -b -r -c 3 2001:470:6a7f:100::11
Start: 2023-03-21T22:23:19+0000
HOST: server3                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2001:470:6a7f:101::254     0.0%     3  105.3 163.5 105.3 199.5  50.8
  2.|-- ???                       100.0     3    0.0   0.0   0.0   0.0   0.0
  3.|-- 2001:470:6a7f:100::11      0.0%     3  107.2 243.6 107.2 385.0 139.0
```

NOTE: Lack of response at hop 2 in the above (leaf1) happens with vQFX.  In production on QFX5120 devices this is not observed with the same configuration.  The same mtr with the real hardware gets a response at hop 2, from the irb.100 unicast address on LEAF1.
