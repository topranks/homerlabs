# eqiadlab

![eqiadlab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/eqiadlab/diagram.png)

This is a containerlab topology based on my previous [evpnlab](../evpnlab), but with two vMX devices added to simulate core/border routers.

Please follow the instrucitions in the evpnlab repo for guidance on how to run the lab.  The only additional requirement here is to have a vrnetlab-based vMX container available to docker.  The topology file will look for a docker image called `vrnetlab/vr-vmx:21.2R1.10`, but you can replace with whatever the name of your local vMX container is.  Building the vrnetlab container for vMX is much the same as for the vQFX, only difference is you need the oriringal tgz file from Juniper (not the extracted VM images).

