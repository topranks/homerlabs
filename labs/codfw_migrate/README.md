# codfw_migrate

![codfw_migrate topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/codfw_migrate/diagram.png)

### Overview

This is a containerlab topology, expanding on [esilab](../esilab), which I used to test a miration of from virtual-chassis based row-wide vlans to EVPN based simulating the kind of move required in codfw row A/B.  

A single vQFX node, vcsw, is used to represent the virtual-chassis (for the purpose of the lab simulating the VC is not relevant).  Two vMX nodes simulate our two coure routers, and a further 4 vQFX act as a basic spine/leaf using EVPN.  Two servers are connected to the vcsw.  Because it is difficult to move cables in containerlab while running two more with similar names are connected to the LEAF devices, which will be used to simulate IP/MAC address move by configuring the same numbering on them and shutting one, bringing up the other.  The server nodes are basic debian-based Linux containers with BIRD installed.  Two additional nodes, remote1 and remote2, are included to act as a source/destination outside the WMF network / rows in question.  These are also plain linux containers.
