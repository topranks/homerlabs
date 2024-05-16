# rrlab

![rrlab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/rrlab/diagram.png)

### Overview

This is a containerlab topology to test route propagation from a LEAF device connected to two Spines (1, 2), and another Leaf device 
connected to two others (3, 4).  The Spines act as IBGP rotue reflectors for their downstream connected LEAF device, and also peer with 
each other.  Each Spine uses a unique route-reflector cluster ID so they announce and accept routes sent by other Spines, and 
propagate them onwards to their own RR clients (the single leaf).


### Checks

The homer topology will configure network 198.18.100.0/24 on Leaf1, and 198.18.200.0/24 on Leaf2.  All are within the 'PRODUCTION' vrf 
and routes should be learnt in the EVPN SAFI.

When configured we can see that Leaf2 is learning the networks (and individual IRB interface host IPs) that are on Leaf1:
```
root@LEAF2> show route receive-protocol bgp 3.3.3.3 table bgp.evpn.0 terse 

bgp.evpn.0: 16 destinations, 20 routes (16 active, 0 holddown, 0 hidden)
  Prefix                  Nexthop              MED     Lclpref    AS path
  5:11.11.11.11:5000::0::198.18.100.0::24/248                   
*                         11.11.11.11                  100        I
  5:11.11.11.11:5000::0::198.18.100.1::32/248                   
*                         11.11.11.11                  100        I
  5:11.11.11.11:5000::0::2001:470:6a7f:100::::64/248                   
*                         11.11.11.11                  100        I
  5:11.11.11.11:5000::0::2001:470:6a7f:100::1::128/248                   
*                         11.11.11.11                  100        I
```

These make it into the vrf routing table as expected:
```
root@LEAF2> show route table PRODUCTION.inet.0 terse 

PRODUCTION.inet.0: 4 destinations, 4 routes (4 active, 0 holddown, 0 hidden)
@ = Routing Use Only, # = Forwarding Use Only
+ = Active Route, - = Last Active, * = Both

A V Destination        P Prf   Metric 1   Metric 2  Next hop        AS path
* ? 198.18.100.0/24    E 170                     3 >10.2.3.0
                                                    10.2.4.0
* ? 198.18.100.1/32    E 170                     3 >10.2.3.0
                                                    10.2.4.0
* ? 198.18.200.0/24    D   0                       >irb.200     
* ? 198.18.200.1/32    L   0                        Local
```

And we can ping between networks
```
root@LEAF2> ping routing-instance PRODUCTION 198.18.100.1 source 198.18.200.1    
PING 198.18.100.1 (198.18.100.1): 56 data bytes
64 bytes from 198.18.100.1: icmp_seq=0 ttl=64 time=251.628 ms
64 bytes from 198.18.100.1: icmp_seq=1 ttl=64 time=111.489 ms
64 bytes from 198.18.100.1: icmp_seq=2 ttl=64 time=110.749 ms
```

