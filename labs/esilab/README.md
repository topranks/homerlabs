# esilab

![esilab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/esilab/diagram.png)

### Overview

This is a containerlab topology based on [evpnlab](../evpnlab) and [eqiadlab](../eqiadlab), but with a vQFX device replacing SERVER1, and additional automation to configure ESI-based LAGs using BGP EVPN.

Initialising the lab is the same as for [eqiadlab](../eqiadlab), so please follow the instructions there to get things spun up.

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

