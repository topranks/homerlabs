# evpnlab

![evpnlab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/evpnlab/diagram.png)

## Running the lab

Specific instructions for this lab can be found in [INIT.md](INIT.md) in this directory.

Users should have installed everything as described in [getting started](../../getting_started.md), and be familiar with the generic steps described there to run labs.


## Lab Description

### VXLAN Fabric

The lab is based on vQFX devices, which are placed in a Spine/Leaf topology with 2 Spine devices and 3 Leaf devices.

OSPF is used as the underlay routing protcol between all these devices, all in area 0.0.0.0 and OSPFv2 only.

BGP EVPN is running between the vQFX devices also, to exchange information about overlay layer-2 and layer-3 networks.  It is an IBGP setup with the Spine devices acting as route reflectors.  All peering is between device loopback IPs knwon through OSPF.  Spines peer with all other Spines, and each Leaf peers with its directly connected Spines.  Leaf devices do not peer with each other, the Spine route reflection ensures they learn routes with destinations on remote Leaf switches.

The Leaf switches provided the local IP gateway for the connected test servers.  LEAF1 and LEAF2 share a common Vlan, Vlan 100, which is bound to a VXLAN VNI.  They use an EVPN anycast gateway on this vlan with the same IP gateway configured on both switches.  Server1 and Server2 attach to this Vlan, one off each of the switches.

LEAF3 has a different Vlan, VLAN101, configured, which Server3 attaches to.  While Juniper only supports assymetric IRB for VXLAN with type-2 EVPN routes, which on its own means all Vlans/VNIs need to be configured on all siwtches to allow for optimal routing, we overcome this in the lab with the use of EVPN type 5 routes.

### Optimal forwarding without configuring all Vlans on all Leaf devices

The Leaf switches are configured to export all local EVPN routes as type 5 EVPN ip-prefix routes as well.  This means that, for instance, LEAF3 learns /32 host routes for individual IPs in the Vlan100 subnet (198.18.100.0/24) through the L3VNI, without having the L2VNI for Vlan100 configured locally.  

Looking at the overlay routing table on LEAF3 we can see examples of this, for the IP addresses configured on Server1 and Server2:

```
root@LEAF3> show route table WMF_PROD.inet.0 198.18.100.8/29 detail | match "198.18|VTEP|VNI|via"         
198.18.100.11/32 (1 entry, 1 announced)
                Next hop: 10.3.1.0 via xe-0/0/0.0
                Next hop: 10.3.2.0 via xe-0/0/1.0, selected
                    Encap VNI: 5000, Decap VNI: 5000
                    Source VTEP: 13.13.13.13, Destination VTEP: 11.11.11.11
198.18.100.12/32 (1 entry, 1 announced)
                Next hop: 10.3.1.0 via xe-0/0/0.0
                Next hop: 10.3.2.0 via xe-0/0/1.0, selected
                    Encap VNI: 5000, Decap VNI: 5000
                    Source VTEP: 13.13.13.13, Destination VTEP: 12.12.12.12
```

In both cases the LEAF forward traffic for these IPs via the Spine switches with ECMP, as can be seen from the next-hops listed.  But the 'destination VTEP' is different for each, reflecting the fact that one destination is reachable via LEAF1, and the other via LEAF2.  The VNI used in the VXLAN encapsulation of both is the L3VNI from the type-5 EVPN routes.

### External connections 

Two 'CORE' devices are also part of the lab.  These are cRPD devices intended to act as a basic way to test routing outside of the VXLAN fabric.  Each Spine switch has a link to one of the Core switches.  The core devices announce only a default route to the Spine layer.  On the Spine side the BGP sessions terminate in the WMF_PROD overlay routing instance, and the Spine announces all local and EVPN routes to the cores.

Worth noting is the configuration in the outbound policy towards the COREs on the SPINE devices:
```
set policy-options policy-statement EXT_OUT term EVPN_NETWORKS then metric expression metric2 multiplier 100
```

This use of the `mertic expression` configuration sets the BGP MED attribute on the routes sent to the core routers to 100 times the 'metric2' value the SPINE switches see.  The metric2 the Spines see will either be 0 (for locally connected routes), or the OSPF cost to get to the VTEP for EVPN routes.  To understand the affect of this look at the routes CORE2 has for the Vlan101 subnet:
```
root@CORE2> show route table inet.0 198.18.101.0/24          

inet.0: 9 destinations, 13 routes (9 active, 0 holddown, 0 hidden)
+ = Active Route, - = Last Active, * = Both

198.18.101.0/24    *[BGP/170] 00:00:48, MED 100, localpref 100
                      AS path: 65187 I, validation-state: unverified
                    >  to 100.64.2.0 via eth2
                    [BGP/170] 01:05:06, MED 100, localpref 100
                      AS path: 65187 I, validation-state: unverified
                    >  to 100.64.0.1 via eth1
```

The first route is the direct route, out eth2, to SPINE2, which it has selected as best.  The second route it has learnt from IBGP on eth1 from CORE1, and it hasn't picked this as it prefers EBGP over IBGP.

Looking on SPINE2 we can see that the 'metric2' value for its route to this is '1', which is what makes the MED 100 on the core (due to the multiplier config):
```
root@SPINE2> show route table WMF_PROD.inet.0 198.18.101.0/24 terse exact 

WMF_PROD.inet.0: 13 destinations, 18 routes (13 active, 0 holddown, 0 hidden)
@ = Routing Use Only, # = Forwarding Use Only
+ = Active Route, - = Last Active, * = Both

A V Destination        P Prf   Metric 1   Metric 2  Next hop        AS path
* ? 198.18.101.0/24    E 170                     1 >10.3.2.1
```

Now suppose we disable the interface from SPINE2 to LEAF3.  SPINE2 should still be able to reach LEAF3, via one of the other LEAF switches, then SPINE1 and eventually to LEAF3.  
```
root@SPINE2> configure 
Entering configuration mode

{master:0}[edit]
root@SPINE2# set interfaces xe-0/0/2 disable 

{master:0}[edit]
root@SPINE2# commit 
configuration check succeeds
commit complete
```
```
root@SPINE2> show route table WMF_PROD.inet.0 198.18.101.0/24 terse exact    

WMF_PROD.inet.0: 13 destinations, 18 routes (13 active, 0 holddown, 0 hidden)
@ = Routing Use Only, # = Forwarding Use Only
+ = Active Route, - = Last Active, * = Both

A V Destination        P Prf   Metric 1   Metric 2  Next hop        AS path
* ? 198.18.101.0/24    E 170                     3 >10.1.2.1
                                                    10.2.2.1
```

We can see that SPINE2 still has a route to this prefix, as expected, but the Metric 2 value (OSPF cost) has increased from 1 to 3 as there are more hops in the path.  

Checking back on CORE2 we can see the effect this has on routing:
```
root@CORE2> show route table inet.0 198.18.101.0/24    

inet.0: 9 destinations, 13 routes (9 active, 0 holddown, 0 hidden)
+ = Active Route, - = Last Active, * = Both

198.18.101.0/24    *[BGP/170] 01:10:23, MED 100, localpref 100
                      AS path: 65187 I, validation-state: unverified
                    >  to 100.64.0.1 via eth1
                    [BGP/170] 00:01:23, MED 300, localpref 100
                      AS path: 65187 I, validation-state: unverified
                    >  to 100.64.2.0 via eth2
```

CORE2 is now prefering the route it's learning in IBGP from CORE1 for this range.  We can see the 'MED' value is now set to 300 for the route out eth2, which is why it's prefering the route from it's IBGP peer.

This configuration ensures that if a link from SPINE->LEAF breaks, the CORE routers will not send traffic for that LEAF to the SPINE that has lost its direct connection to it.  It prevents traffic going from CORE2 -> SPINE2 -> LEAF[1|2] -> SPINE1 -> LEAF3, instead ensuring it goes CORE2 -> CORE1 -> SPINE1 -> LEAF3.

