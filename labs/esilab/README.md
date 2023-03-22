# esilab

![esilab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/esilab/diagram.png)

### Overview

This is a containerlab topology based on [evpnlab](../evpnlab) and [eqiadlab](../eqiadlab), but with a vQFX device replacing SERVER1, and additional automation to configure ESI-based LAGs using BGP EVPN.

### ESI-LAG

When the automation runs the ESI-LAG is built between LEAF1 and LEAF2, and in the output you can see it working.

Connected device SERVER has its ae0 interface configured as a routed interface with IP 198.18.100.101, its MAC is 02:05:86:72:c9:ef.

LEAF1:
```
cathal@LEAF1> show evpn database esi 00:00:00:00:01:02:00:00:00:01 extensive 
Instance: default-switch

VN Identifier: 100000, MAC address: 02:05:86:72:c9:ef
  State: 0x0
  Source: 00:00:00:00:01:02:00:00:00:01, Rank: 1, Status: Active
    Local origin: ae0.0
    Remote origin: 12.12.12.12
    Mobility sequence number: 0 (minimum origin address 11.11.11.11)
    Timestamp: Mar 02 23:40:39 (0x640133f7)
    State: <Local-MAC-Only Local-To-Remote-Adv-Allowed>
    MAC advertisement route status: Created
    IP address: 198.18.100.101
      Local origin: ae0.0
      Remote origin: 12.12.12.12
      L3 route: 198.18.100.101/32, L3 context: WMF_PROD (irb.100)
    History db: 
      Time                  Event
      Mar  2 23:40:37 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Selected IRB interface nexthop
      Mar  2 23:40:37 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x80 <ESI-Local-State>)
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400000000 <ESI-Remote-Peer-Com-Chg>)
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Selected IRB interface nexthop
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.101 Selected IRB interface nexthop
      Mar  2 23:46:43 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400000000 <ESI-Remote-Peer-Com-Chg>)
      Mar  2 23:46:43 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Selected IRB interface nexthop
      Mar  2 23:46:43 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.101 Selected IRB interface nexthop
      Mar  2 23:46:52 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Deleting
      Mar  2 23:46:52 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x1000 <IP-Deleted>)

{master:0}
cathal@LEAF1> show lacp interfaces extensive 
Aggregated interface: ae0
    LACP state:       Role   Exp   Def  Dist  Col  Syn  Aggr  Timeout  Activity
      xe-0/0/2       Actor    No    No   Yes  Yes  Yes   Yes     Fast    Active
      xe-0/0/2     Partner    No    No   Yes  Yes  Yes   Yes     Fast    Active
    LACP protocol:        Receive State  Transmit State          Mux State 
      xe-0/0/2                  Current   Fast periodic Collecting distributing
    LACP info:        Role     System             System       Port     Port    Port 
                             priority         identifier   priority   number     key 
      xe-0/0/2       Actor        127  01:02:00:00:00:01        127        1       1
      xe-0/0/2     Partner        127  02:05:86:71:ce:00        127        1       1
```

LEAF2:
```
cathal@LEAF2> show evpn database esi 00:00:00:00:01:02:00:00:00:01 extensive 
Instance: default-switch

VN Identifier: 100000, MAC address: 02:05:86:72:c9:ef
  State: 0x0
  Source: 00:00:00:00:01:02:00:00:00:01, Rank: 1, Status: Active
    Local origin: ae0.0
    Remote origin: 11.11.11.11
    Mobility sequence number: 0 (minimum origin address 11.11.11.11)
    Timestamp: Mar 02 23:40:38 (0x640133f6)
    State: <Local-MAC-Only Local-To-Remote-Adv-Allowed>
    MAC advertisement route status: Created
    IP address: 198.18.100.101
      Local origin: ae0.0
      Remote origin: 11.11.11.11
      L3 route: 198.18.100.101/32, L3 context: WMF_PROD (irb.100)
    History db: 
      Time                  Event
      Mar  2 23:36:40 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x80 <ESI-Local-State>)
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : Remote peer 11.11.11.11 created
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400000a00 <ESI-Peer-Added IP-Added ESI-Remote-Peer-Com-Chg>)
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Selected IRB interface nexthop
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.101 Selected IRB interface nexthop
      Mar  2 23:40:38 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.101 Selected IRB interface nexthop
      Mar  2 23:46:43 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Selected IRB interface nexthop
      Mar  2 23:46:53 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.100 Deleting
      Mar  2 23:46:53 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400001000 <IP-Deleted ESI-Remote-Peer-Com-Chg>)
      Mar  2 23:46:53 2023  00:00:00:00:01:02:00:00:00:01 : 198.18.100.101 Selected IRB interface nexthop

cathal@LEAF2> show lacp interfaces extensive 
Aggregated interface: ae0
    LACP state:       Role   Exp   Def  Dist  Col  Syn  Aggr  Timeout  Activity
      xe-0/0/2       Actor    No    No   Yes  Yes  Yes   Yes     Fast    Active
      xe-0/0/2     Partner    No    No   Yes  Yes  Yes   Yes     Fast    Active
    LACP protocol:        Receive State  Transmit State          Mux State 
      xe-0/0/2                  Current   Fast periodic Collecting distributing
    LACP info:        Role     System             System       Port     Port    Port 
                             priority         identifier   priority   number     key 
      xe-0/0/2       Actor        127  01:02:00:00:00:01        127        1       1
      xe-0/0/2     Partner        127  02:05:86:71:ce:00        127        2       1
```

LAG looks ok on SERVER1 (standard LAG across 2 local ports):
```
cathal@SERVER1> show lacp interfaces extensive 
Aggregated interface: ae0
    LACP state:       Role   Exp   Def  Dist  Col  Syn  Aggr  Timeout  Activity
      xe-0/0/0       Actor    No    No   Yes  Yes  Yes   Yes     Fast    Active
      xe-0/0/0     Partner    No    No   Yes  Yes  Yes   Yes     Fast    Active
      xe-0/0/1       Actor    No    No   Yes  Yes  Yes   Yes     Fast    Active
      xe-0/0/1     Partner    No    No   Yes  Yes  Yes   Yes     Fast    Active
    LACP protocol:        Receive State  Transmit State          Mux State 
      xe-0/0/0                  Current   Fast periodic Collecting distributing
      xe-0/0/1                  Current   Fast periodic Collecting distributing
    LACP info:        Role     System             System       Port     Port    Port 
                             priority         identifier   priority   number     key 
      xe-0/0/0       Actor        127  02:05:86:71:ce:00        127        1       1
      xe-0/0/0     Partner        127  01:02:00:00:00:01        127        1       1
      xe-0/0/1       Actor        127  02:05:86:71:ce:00        127        2       1
      xe-0/0/1     Partner        127  01:02:00:00:00:01        127        1       1
```

Failover seems to all work as expected.  Run the `config_servers.sh` script to add IPv4 addressing to the Debian containers to run pings while testing.



### Initializing the lab

Pretty much the same as for eqiadlab.  Users should have installed everything as described in [getting started](../../getting_started.md), and be familiar with the generic steps described there to run labs.  Below is a high-level overview:

##### 1. Change to the lab directory and init the lab with containerlab:
```
cd ~/homerlabs/labs/esilab
sudo clab deploy -t esilab.yaml
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

#### 4. Add user config to vMX devices manually

The default user/pass for the vMX isn't clear, so we need to add our user manually.  For example for core1 (make sure to use your own SSH public key not the one shown below):
```
cathal@officepc:~$ sudo ip netns exec clab-esilab-core1 telnet localhost 5000 
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.

root@:~ # cli
root@core1> 

root@core1> configure 
Entering configuration mode

[edit]
root@core1# set system login user homer class super-user 

[edit]
root@core1# set system login user homer authentication ssh-ed25519 "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFyIygMcbB1dZpJodQCTd1kqhXWIWu2KKjztnxyq6KCX cathal@officepc" 

[edit]
root@core1# commit 
commit complete

[edit]
root@core1# exit 
Exiting configuration mode

root@core1> 
```

We can exit the telnet session with CTRL + ], and then typing quit:
```
telnet> quit
Connection closed.
```

After which we should be able to SSH:
```
cathal@officepc:~$ ssh -i ~/.ssh/homerlabs_ed25519 homer@core1
Last login: Tue Mar 21 23:31:31 2023 from 10.0.0.2
--- JUNOS 21.2R1.10 Kernel 64-bit  JNPR-12.1-20210529.2f59a40_buil
homer@core1> 
```

Repeat for core2.

##### 5. Configure the JunOS devices with Homer:
```
homer '*' commit "configure esilab"
```

##### 5. Configure server container IP addressing

Run the `config_servers.sh` shell script from the lab dir to add basic IP configuration to the containers simulating end servers:
```
cathal@officepc:~/homerlabs/labs/esilab$ ./config_servers.sh 
+ sudo ip netns exec clab-esilab-server2 ip addr add 198.18.100.102/24 dev eth1
+ sudo ip netns exec clab-esilab-server2 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-esilab-server3 ip addr add 198.18.100.103/24 dev eth1
+ sudo ip netns exec clab-esilab-server3 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-esilab-server4 ip addr add 198.18.200.201/24 dev eth1
+ sudo ip netns exec clab-esilab-server4 ip route add 198.18.0.0/16 via 198.18.200.254
+ sudo ip netns exec clab-esilab-server5 ip addr add 198.18.100.105/24 dev eth1
+ sudo ip netns exec clab-esilab-server5 ip route add 198.18.0.0/16 via 198.18.100.254
```

### TODO

Add IPv6 config to the server script.
