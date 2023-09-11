# codfw_migrate

![codfw_migrate topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/codfw_migrate/diagram.png)

## Overview

This is a containerlab topology, expanding on [esilab](../esilab), which I used to test a miration of from virtual-chassis based row-wide vlans to EVPN based simulating the kind of move required in codfw row A/B.  

A single vQFX node, **ASW**, is used to represent the virtual-chassis (for the purpose of the lab simulating a VC is not required).  Two vMX nodes simulate our two core routers, and a further 4 vQFX act as a basic spine/leaf running EVPN.  

Two servers are connected to the ASW.  Because it is difficult to move cables in containerlab while running, two more with similar names are connected to the LEAF devices.  Server moves will then be simulated by configuring the same MAC/IP addressing on, for instance, server1 and server1_b, then shutting the link to server1 and bringing the link to server1_b up.  The server nodes are basic debian-based Linux containers with BIRD installed.  Two additional nodes, remote1 and remote2, are included to act as a source/destination outside the WMF network / rows in question.  These are also plain linux containers.

Similar to the server move to simulate disconnecting the ASW from core routers, and moving them to the SPINEs, the links to the cores will instead be shut down before the separate links to the SPINEs brought up.

## IP GW Migration

Vlan 100 is used to simulate a vlan on the VC switch, which we want to bridge into the LEAF/SPINE devices which are configured to use VXLAN/EVPN.  In the real world we will disconnect the VC switch links to the core routers, and move them to the Spine switches.  For the purpose of the lab we have separate connections between devices, as "moving" links is difficult in this context.  In the lab we'll instead shut down one link, and bring up the other, to simulate cable moves.

### Strategy

The key concern when moving the gateway IPs (v4 and v6) for the subnet is that end-hosts may have cached ARP/ND entries which associate the GW IP with a specific MAC.  In this case the VRRP virtual MAC shared by the two core routers.  This MAC is used as the destination address in the Ethernet header hosts on the vlan use to reach systems outside the local subnet.

In VRRP the MAC is created based on the VRRP group ID configured on participating hosts.  That means regardless of what IP is configured as the VRRP VIP on (for example) group 10, the virtual MAC will be the same.  Knowing that is the case we can thus change the VRRP VIP on the core routers, while keeping the virtual MAC "alive".  In other words the VRRP VIP can change, but the core routers will continue to process frames sent to the virtual MAC, and the MAC will continue to be in the L2 forwarding tables of all devices on the Vlan.  We can use this property to give us a window, during which end-hosts may have either the old or new MAC for the subnet's gateway in their ARP/ND cache, and still ensure all packets are forwarded.  Roughly speaking the steps are as follows:

1. Move the virtual-chassis link that connects to CORE2 to SPINE1, bridging the Vlan to SPINE1 / VXLAN fabirc.
2. Enable the IRB / Anycast GW interface on the SPINE switches so they begin to answer ARP/ND queries for the GW IP
  ** At this point there is an IP conflict on the network, devices may get either the VRRP or Anycast GW MAC if they ARP/ND for the gateway.
3. Change the VRRP VIP on the core routers so they no longer answer ARP/ND queries for the GW IP
   ** At this point anything that ARPs for the GW will get the Anycast MAC belonging to the Spines
   ** Traffic sent to the VRRP MAC by hosts with cached entry will still be forwarded by the cores, however
4. Wait for ARP/ND to expire or force update the ARP/ND cache on end hosts
   ** After which all hosts will be sending outbound traffic to the Anycast MAC / Spines
5. Move the remaining virtual-chassis link from CORE1 to SPINE2, taking the CORE routers completely out of the Vlan.

### Initial state

At the start of the process the VC switch is connected to both core routers, and both links from it to the SPINEs are down:
```
root@ASW> show interfaces descriptions 
Interface       Admin Link Description
xe-0/0/0        up    up   CORE1 ge-0/0/2
xe-0/0/1        up    up   CORE2 ge-0/0/2
xe-0/0/2        down  down SPINE1 xe-0/0/2
xe-0/0/3        down  down SPINE2 xe-0/0/2
xe-0/0/4        up    up   SERVER1 eth1
xe-0/0/5        up    up   SERVER2 eth1
ae0             up    down SPINES MC-LAG ae0
em1             up    up   LINK TO vQFX PFE
```

The core routers are both connected to the ASW and are sharing VRRP VIPs of 10.192.0.1 / 2620:0:860:101::1, the IP gateways for hosts on Vlan 100.  Core1 is VRRP master:
```
root@core1> show vrrp summary 
Interface     State       Group   VR state       VR Mode    Type   Address 
ge-0/0/2.0    up             10   master          Active    lcl    10.192.0.2         
                                                            vip    10.192.0.1         
ge-0/0/2.0    up             10   master          Active    lcl    2620:0:860:101::2  
                                                            vip    fe80::200:5eff:fe00:20a
                                                            vip    2620:0:860:101::1  
```
```
root@core2> show vrrp summary 
Interface     State       Group   VR state       VR Mode    Type   Address 
ge-0/0/2.0    up             10   backup          Active    lcl    10.192.0.3         
                                                            vip    10.192.0.1         
ge-0/0/2.0    up             10   backup          Active    lcl    2620:0:860:101::3  
                                                            vip    fe80::200:5eff:fe00:20a
                                                            vip    2620:0:860:101::1  
```

Server1 is connected to this vlan, using IP 10.192.0.11 / 2620:0:860:101::11:

```
root@server1:~# ip -br addr show dev eth1 
eth1@if80        UP             10.192.0.11/22 2620:0:860:101::11/64
```

It's default gateway is set to the VRRP VIP of the cores:
```
root@server1:~# ip route show default 
default via 10.192.0.1 dev eth1 
root@server1:~# 
root@server1:~# 
root@server1:~# ip -6 route show default 
default via 2620:0:860:101::1 dev eth1 metric 1024 pref medium
```

And if we look at the ARP / ND table we can see the VRRP virtual MACs are assocaited with the gateway IPs currently:

```
root@server1:~# ip neigh show 10.192.0.1 
10.192.0.1 dev eth1 lladdr 00:00:5e:00:01:0a REACHABLE
root@server1:~# 
root@server1:~# 
root@server1:~# ip neigh show 2620:0:860:101::1
2620:0:860:101::1 dev eth1 lladdr 00:00:5e:00:02:0a router REACHABLE
```

This allows us to get to each of the remote servers.  Traffic to remote1 hits CORE1 as it is VRRP master and goes directly out to it:
```
root@server1:~# mtr -n -r -c 3 100.64.100.5
Start: 2023-09-11T20:39:23+0000
HOST: server1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.192.0.2                 0.0%     3  101.1 100.8 100.7 101.1   0.3
  2.|-- 100.64.100.5               0.0%     3  100.7 134.0 100.6 200.6  57.7
root@server1:~# 
root@server1:~# 
root@server1:~# mtr -6 -n -r -c 3 2620:0:860:3:fe00::2
Start: 2023-09-11T20:40:12+0000
HOST: server1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2620:0:860:101::2          0.0%     3  108.0 106.0 101.6 108.3   3.8
  2.|-- 2620:0:860:3:fe00::2       0.0%     3  101.6 134.7 101.1 201.4  57.8
```

For remote2 traffic still goes via CORE1 (VRRP master), but then uses the direct link to CORE2 and out:
```
root@server1:~# mtr -n -r -c 3 100.64.100.7
Start: 2023-09-11T20:39:13+0000
HOST: server1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.192.0.2                 0.0%     3  100.7 100.9 100.6 101.3   0.4
  2.|-- 198.18.11.1                0.0%     3  153.2 151.7 101.1 200.9  49.9
  3.|-- 100.64.100.7               0.0%     3  100.7 134.0 100.5 200.8  57.9
root@server1:~# 
root@server1:~# 
root@server1:~# mtr -6 -n -r -c 3 2620:0:860:4:fe00::2
Start: 2023-09-11T20:41:56+0000
HOST: server1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2620:0:860:101::2          0.0%     3  100.8 129.6 100.8 187.1  49.8
  2.|-- 2620:0:860:5:fe00::2       0.0%     3  191.3 192.7 187.0 199.8   6.5
  3.|-- 2620:0:860:4:fe00::2       0.0%     3  100.7 129.3 100.4 186.9  49.9
```

Traffic from remote1 back to server1 takes the same path in reverse:
```
root@remote1:~# mtr -n -r -c 3 10.192.0.11
Start: 2023-09-11T19:46:48+0000
HOST: remote1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 100.64.100.4               0.0%     3    0.6   0.6   0.6   0.7   0.1
  2.|-- 10.192.0.11                0.0%     3  102.1 134.8 102.0 200.4  56.8
root@remote1:~# 
root@remote1:~# 
root@remote1:~# mtr -n -r -c 3 2620:0:860:101::11
Start: 2023-09-11T19:47:18+0000
HOST: remote1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2620:0:860:3:fe00::1       0.0%     3    0.5   3.7   0.5   9.9   5.4
  2.|-- 2620:0:860:101::11         0.0%     3  102.0 105.3 101.6 112.2   6.0
```

Traffic from remote2 goes out via its link to CORE2, but then it goes directly to the ASW and out to server1 as it is directly connected to the vlan.
```
root@remote2:~# mtr -n -r -c 3 10.192.0.11
Start: 2023-09-11T19:48:26+0000
HOST: remote2                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 100.64.100.6               0.0%     3    0.7   0.6   0.5   0.7   0.1
  2.|-- 10.192.0.11                0.0%     3  150.5 119.2 102.5 150.5  27.1
root@remote2:~# 
root@remote2:~# 
root@remote2:~# mtr -n -r -c 3 2620:0:860:101::11
Start: 2023-09-11T20:03:53+0000
HOST: remote2                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2620:0:860:4:fe00::1       0.0%     3    0.9   0.8   0.7   0.9   0.1
  2.|-- 2620:0:860:101::11         0.0%     3  102.5 132.5 102.5 192.3  51.8
```

### Migration Steps

##### Step 1: Disconnect CORE2 from ASW

Due to lack of free ports on the real virtual-chassis switches we cannot pre-cable them to the newly installed SPINE devices.  So we will disconnect one link from ASW -> CRs first, connect that to a SPINE switch, migrate the IP gateway, then move the other link from ASW to SPINEs.

To simulate this move in the lab we use separate links, as we re-initializing the lab to simulate a link move can be tricky.  So instead we just shut down the link from ASW to CORE2 to simulate when we unplug the link.  

As CORE1 is still VRRP master outbound traffic from the server takes the same path.  The biggest change we can observe is that return traffic from remote2 now goes to CORE1 after CORE2, as CORE2 is no longer connected to the vlan.
```
root@remote2:~# mtr -n -r -c 3 10.192.0.11
Start: 2023-09-11T21:08:13+0000
HOST: remote2                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 100.64.100.6               0.0%     3   10.0   3.9   0.7  10.0   5.4
  2.|-- 198.18.11.0                0.0%     3    1.4   1.3   1.1   1.4   0.1
  3.|-- 10.192.0.11                0.0%     3  101.8 102.2 101.8 102.6   0.4
root@remote2:~#
root@remote2:~# 
root@remote2:~# mtr -n -r -c 3 2620:0:860:101::11
Start: 2023-09-11T21:08:24+0000
HOST: remote2                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2620:0:860:4:fe00::1       0.0%     3    0.7   0.6   0.4   0.8   0.2
  2.|-- 2620:0:860:5:fe00::1       0.0%     3    1.2   1.2   1.1   1.3   0.1
  3.|-- 2620:0:860:101::11         0.0%     3  102.2 102.2 101.7 102.8   0.6
```

##### Step 2: Connect SPINE2 to ASW

Next we want to bring up the link to SPINE2 from the ASW, simulating moving the CORE2 link to SPINE2.  Once enabled we should see the AE interface also come up:
```
root@ASW> show interfaces descriptions    
Interface       Admin Link Description
xe-0/0/0        up    up   CORE1 ge-0/0/2
xe-0/0/1        down  down CORE2 ge-0/0/2
xe-0/0/2        down  down SPINE1 xe-0/0/2
xe-0/0/3        up    up   SPINE2 xe-0/0/2
xe-0/0/4        up    up   SERVER1 eth1
xe-0/0/5        up    up   SERVER2 eth1
ae0             up    up   SPINES MC-LAG ae0
```

On the SPINE2 side we see the physical as well as AE0 interface come up:
```
root@SPINE2> show interfaces descriptions 
Interface       Admin Link Description
xe-0/0/0        up    up   LEAF1 xe-0/0/1
xe-0/0/1        up    up   LEAF2 xe-0/0/1
xe-0/0/2        up    up   ASW xe-0/0/3
xe-0/0/3        up    up   CORE2 ge-0/0/1
ae0             up    up   ASW ae0
em1             up    up   LINK TO vQFX PFE
irb.100         down  up   VLAN100 GW
lo0.0           up    up   System Loopback
```

It's worth noting that irb.100 now shows link "up", as VLAN100 is now live on the spine, due to the access interface ae0 coming UP.  It is still admin down, however, so it will not answer ARP/ND requests, and the SPINE still has no IP on the 10.192.0.0/22 subnet.

SPINE1 we see the AE0 interface down, as it has no active ports in it:
```
root@SPINE1> show interfaces descriptions 
Interface       Admin Link Description
xe-0/0/0        up    up   LEAF1 xe-0/0/0
xe-0/0/1        up    up   LEAF2 xe-0/0/0
xe-0/0/2        down  down ASW xe-0/0/2
xe-0/0/3        up    up   CORE1 ge-0/0/1
ae0             up    down ASW ae0
```

This change has no effect on trafic patterns.  It *does* bridge the Vlan from the ASW to the LEAF/SPINE network, however.  We can see this if we go to Server1_b connected to LEAF1, and try to ping Server1:
```
root@server1_b:~# ping -c 2 10.192.0.11
PING 10.192.0.11 (10.192.0.11) 56(84) bytes of data.
64 bytes from 10.192.0.11: icmp_seq=1 ttl=64 time=105 ms
64 bytes from 10.192.0.11: icmp_seq=2 ttl=64 time=105 ms

--- 10.192.0.11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 105.317/105.326/105.336/0.009 ms
root@server1_b:~# 
root@server1_b:~# 
root@server1_b:~# ping -c 2 2620:0:860:101::11
PING 2620:0:860:101::11(2620:0:860:101::11) 56 data bytes
64 bytes from 2620:0:860:101::11: icmp_seq=1 ttl=64 time=108 ms
64 bytes from 2620:0:860:101::11: icmp_seq=2 ttl=64 time=265 ms

--- 2620:0:860:101::11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 108.165/186.793/265.421/78.628 ms
root@server1_b:~#
root@server1_b:~#
root@server1_b:~# ip neigh show 10.192.0.11
10.192.0.11 dev eth1 lladdr aa:c1:ab:16:40:89 REACHABLE
root@server1_b:~#
root@server1_b:~#
root@server1_b:~# ip neigh show 2620:0:860:101::11
2620:0:860:101::11 dev eth1 lladdr aa:c1:ab:16:40:89 REACHABLE
```

If we look on the ASW we can see we learn the MAC address of Server1_B on the port that was just brought up:
```
root@server1_b:~# ip -br link show dev eth1 
eth1@if68        UP             aa:c1:ab:39:5f:31 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```
```
root@ASW> show ethernet-switching table interface ae0.0 

MAC database for interface ae0.0

MAC flags (S - static MAC, D - dynamic MAC, L - locally learned, P - Persistent static, C - Control MAC
           SE - statistics enabled, NM - non configured MAC, R - remote PE MAC, O - ovsdb MAC)


Ethernet switching table : 2 entries, 2 learned
Routing instance : default-switch
    Vlan                MAC                 MAC         Age    Logical                NH        RTR 
    name                address             flags              interface              Index     ID
    VLAN100             02:05:86:71:5c:00   D             -   ae0.0                  0         0       
    VLAN100             aa:c1:ab:39:5f:31   D             -   ae0.0                  0         0       
```

Likewise on SPINE2 we learn the Server1 MAC from the local ae0 interface:
```
root@server1:~# ip -br link show dev eth1 
eth1@if80        UP             aa:c1:ab:16:40:89 <BROADCAST,MULTICAST,UP,LOWER_UP>
```
```
root@SPINE2> show ethernet-switching table interface ae0.0 | match aa:c1:ab:16:40:89 
   VLAN100             aa:c1:ab:16:40:89   DL       ae0.0
```

On the other EVPN switches we can see this MAC, and others learnt from the ASW by SPINE2, with outbound interfaces of type "esi":
```
root@LEAF2> show ethernet-switching table vlan-id 100 

MAC flags (S - static MAC, D - dynamic MAC, L - locally learned, P - Persistent static
           SE - statistics enabled, NM - non configured MAC, R - remote PE MAC, O - ovsdb MAC)


Ethernet switching table : 7 entries, 7 learned
Routing instance : default-switch
   Vlan                MAC                 MAC      Logical                Active
   name                address             flags    interface              source
   VLAN100             00:00:5e:00:01:0a   DR       esi.1820               00:00:00:00:01:02:00:00:00:01 
   VLAN100             00:00:5e:00:02:0a   DR       esi.1820               00:00:00:00:01:02:00:00:00:01 
   VLAN100             52:54:00:82:e8:03   DR       esi.1820               00:00:00:00:01:02:00:00:00:01 
   VLAN100             aa:c1:ab:16:40:89   DR       esi.1820               00:00:00:00:01:02:00:00:00:01 
   VLAN100             aa:c1:ab:39:5f:31   D        vtep.32771             11.11.11.11                   
   VLAN100             aa:c1:ab:3a:48:76   DR       esi.1820               00:00:00:00:01:02:00:00:00:01 
   VLAN100             aa:c1:ab:94:c6:f1   D        xe-0/0/2.0           
```

Taking a look in the EVPN database for a given MAC show's that it is reachable via CORE2 using VXLAN:
```
root@LEAF2> show evpn database extensive mac-address aa:c1:ab:16:40:89 
Instance: default-switch

VN Identifier: 100000, MAC address: aa:c1:ab:16:40:89
  State: 0x0
  Source: 00:00:00:00:01:02:00:00:00:01, Rank: 1, Status: Active
    Remote origin: 2.2.2.2
    Mobility sequence number: 0 (minimum origin address 2.2.2.2)
    Timestamp: Sep 11 21:21:10 (0x64ff84c6)
    State: <Remote-To-Local-Adv-Done>
    MAC advertisement route status: Not created (no local state present)
    IP address: 10.192.0.11
      Remote origin: 2.2.2.2
    IP address: 2620:0:860:101::11
      Remote origin: 2.2.2.2
    IP address: fe80::a8c1:abff:fe16:4089
      Remote origin: 2.2.2.2
    History db: 
      Time                  Event
      Sep 11 21:20:34 2023  00:00:00:00:01:02:00:00:00:01 : Remote peer 2.2.2.2 created
      Sep 11 21:20:34 2023  00:00:00:00:01:02:00:00:00:01 : Created
      Sep 11 21:20:34 2023  Updating output state (change flags 0x20 <ESI-Added>)
      Sep 11 21:20:34 2023  Active ESI changing (not assigned -> 00:00:00:00:01:02:00:00:00:01)
      Sep 11 21:20:39 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400000800 <IP-Added ESI-Remote-Peer-Com-Chg>)
      Sep 11 21:21:05 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400000800 <IP-Added ESI-Remote-Peer-Com-Chg>)
      Sep 11 21:21:10 2023  00:00:00:00:01:02:00:00:00:01 : Updating output state (change flags 0x400000800 <IP-Added ESI-Remote-Peer-Com-Chg>)
```


