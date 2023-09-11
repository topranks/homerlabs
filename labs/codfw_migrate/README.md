# codfw_migrate

![codfw_migrate topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/codfw_migrate/diagram.png)

### Overview

This is a containerlab topology, expanding on [esilab](../esilab), which I used to test a miration of from virtual-chassis based row-wide vlans to EVPN based simulating the kind of move required in codfw row A/B.  

A single vQFX node, **vcsw**, is used to represent the virtual-chassis (for the purpose of the lab simulating a VC is not required).  Two vMX nodes simulate our two core routers, and a further 4 vQFX act as a basic spine/leaf running EVPN.  

Two servers are connected to the vcsw.  Because it is difficult to move cables in containerlab while running, two more with similar names are connected to the LEAF devices.  Server moves will then be simulated by configuring the same MAC/IP addressing on, for instance, server1 and server1_b, then shutting the link to server1 and bringing the link to server1_b up.  The server nodes are basic debian-based Linux containers with BIRD installed.  Two additional nodes, remote1 and remote2, are included to act as a source/destination outside the WMF network / rows in question.  These are also plain linux containers.

Similar to the server move to simulate disconnecting the vcsw from core routers, and moving them to the SPINEs, the links to the cores will instead be shut down before the separate links to the SPINEs brought up.

### IP GW Migration

Vlan 100 is used to simulate a vlan on the VC switch, which we want to bridge into the LEAF/SPINE devices which are configured to use VXLAN/EVPN.  In the real world we will disconnect the VC switch links to the core routers, and move them to the Spine switches.  For the purpose of the lab we have separate connections between devices, as "moving" links is difficult in this context.  In the lab we'll instead shut down one link, and bring up the other, to simulate cable moves.

#### Strategy

The key concern when moving the gateway IPs (v4 and v6) for the subnet is that end-hosts may have cached ARP/ND entries which associate the GW IP with a specific MAC.  In this case the VRRP virtual MAC shared by the two core routers.  This MAC is used as the destination address in the Ethernet header hosts on the vlan use to reach systems outside the local subnet.

In VRRP the MAC is created based on the VRRP group ID configured on participating hosts.  That means regardless of what IP is configured as the VRRP VIP on (for example) group 10, the virtual MAC will be the same.  Knowing that is the case we can thus change the VRRP VIP on the core routers, while keeping the virtual MAC "alive".  In other words the VRRP VIP can change, but the core routers will continue to process frames sent to the virtual MAC, and the MAC will continue to be in the L2 forwarding tables of all devices on the Vlan.  We can use this property to give us a window, during which end-hosts may have either the old or new MAC for the subnet's gateway in the ARP/ND caches, and still ensure all packets are forwarded.  Roughly speaking the steps are as follows:

1. Enable the IRB / Anycast GW interface on the SPINE switches so that they will answer ARP/ND queries for the GW IP
  ** At this point there is an IP conflict on the network, devices may get either the VRRP or Anycast GW MAC if they ARP/ND for the gateway.
2. Change the VRRP VIP on the core routers so they no longer answer ARP/ND queries for the GW IP
   ** At this point anything that ARPs for the GW will get the Anycast MAC belonging to the Spines
   ** Traffic sent to the VRRP MAC by hosts with cached entry will still be forwarded by the cores, however
3. Wait to ARP to expire or force update the ARP cache on end hosts
   ** After which all hosts will be sending outbound traffic to the Anycast MAC / Spines
5. Remove the other virtual-chassis link to the Cores, connecting it to Spine2 for redundancy.


#### Initial setup

At the start of the process the VC switch is connected to both core routers, which have a shared VRRP VIP GW for Vlan100 of 10.192.0.1.  Core1 is VRRP master:

