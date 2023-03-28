# filterlab

Lab to test the config from https://www.daryllswer.com/navigating-a-bgp-zombie-outbreak-on-juniper-routers/

![filterlab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/filterlab/diagram.png)

TL;DR I didn't get the same thing on cRPD 19.4R1.10.  So probably a bug in the JunOS version in use in the blog.

### Lab Overview

3 simple containers.  1 cRPD to simualte the TATA internet router, another cRPD to simulate the CLouDINfra edge node, plus a Linux container if any tests are needed from a router 'inside' AS48635.

### Setup

#### 1. Configure container addressing.

Run the attached `config_crpd.sh` script to add device IP addressing.

#### 2. Configure the JunOS devices manually

Get a shell in each of the cRPD devices:
```
cathal@officepc:~$ docker exec -it clab-filterlab-tata /bin/bash 

===>
           Containerized Routing Protocols Daemon (CRPD)
 Copyright (C) 2018-19, Juniper Networks, Inc. All rights reserved.
                                                                    <===

root@tata:/# 
root@tata:/# cli
root@tata> 
```

```
cathal@officepc:~$ docker exec -it clab-filterlab-r1 /bin/bash

===>
           Containerized Routing Protocols Daemon (CRPD)
 Copyright (C) 2018-19, Juniper Networks, Inc. All rights reserved.
                                                                    <===

root@r1:/# cli
root@r1>
```

Configuration was not automated, 'set' command configs that can be applied to are saved in the [saved_configs](saved_configs) dir.


### Results

The R1 routing table has both the more specific subnets that are on the eth2 sub-interfaces, as well as the aggregates that have been generated:
```
root@r1> show route table inet.0          

inet.0: 11 destinations, 11 routes (11 active, 0 holddown, 0 hidden)
+ = Active Route, - = Last Active, * = Both

0.0.0.0/0          *[BGP/170] 00:03:06, localpref 100
                      AS path: 6453 I, validation-state: unverified
                    >  to 80.231.152.77 via eth1
2.57.56.0/22       *[Aggregate/130] 00:08:34
                       Discard
2.57.56.0/24       *[Direct/0] 00:08:34
                    >  via eth2.100
2.57.56.1/32       *[Local/0] 00:08:34
                       Local via eth2.100
5.157.80.0/21      *[Aggregate/130] 00:05:58
                       Discard
5.157.80.0/24      *[Direct/0] 00:05:58
                    >  via eth2.101
5.157.80.1/32      *[Local/0] 00:05:58
                       Local via eth2.101
80.231.152.76/30   *[Direct/0] 00:21:56
                    >  via eth1
80.231.152.78/32   *[Local/0] 00:21:56
                       Local via eth1
```

But only the aggregates are announced to the dummy TATA router, matching the prefix-list used in the export policy:
```
root@r1> show route advertising-protocol bgp 80.231.152.77    

inet.0: 11 destinations, 11 routes (11 active, 0 holddown, 0 hidden)
  Prefix		  Nexthop	       MED     Lclpref    AS path
* 2.57.56.0/22            Self                                    I
* 5.157.80.0/21           Self                                    I
```

So unsure what is happening in the blog, but that's not normal behaviour.  I've never seen it in any of my time using Juniper. I highly doubt a _large part of Zombie routes in the Default-free zone (DFZ) could be due to the bug_ as the blog speculates.  The idea that a bug like that could go unnoticed for a long period of time, in multiple software versions used by large service providers, doesn't seem realistic.
