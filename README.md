# homerlabs
Virtual networking labs built with containerlab, configured with homer.

![example topolgy diagram](https://github.com/topranks/homerlabs/raw/main/diagram.png)

## Overview

This repo contains various virtual networking labs, defined as [containerlab](https://containerlab.srlinux.dev/) topology files and  [homer](https://doc.wikimedia.org/homer/master/introduction.html) device data/template folders.

The files for each lab are saved in separate directories under 'labs' in this repo.  Users can change to that directory, instantiate the virtual devices with 'clab deploy', then configure them with homer.

## Labs

The following labs are currently available.

|Name|Description|
|----|-----------|
|[evpnlab](labs/evpnlab/README.md)|Basic Clos with vQFX running EVPN/VXLAN|
|[eqiadlab](labs/eqiadlab/README.md)|Same as evpnlab with two vMX added to represent core routers|
|[esilab](labs/esilab/README.md)|Same as eqiadlab but with automation for ESI-LAG off two leaf switches|
|[filterlab](labs/filterlab/README.md)|Simple cRPD lab without automation to test prefix-list behaviour|
|[codfw_migrate](labs/codfw_migrate/README.md)|Lab to test migration of row-wide vlan / hosts from virtual-chassis to EVPN clos|

## How it works

Containerlab is a framework which allows us to spin up virtual network topologies with docker containers.  A [YAML file](https://containerlab.dev/manual/topo-def-file/) is used to define the various nodes to deploy, and the links between them.

### Images

To instantiate a lab we need the clab topology file, as well as a working docker subsystem on the local host.  Container images referenced in the clab file should be available locally, and show up when `docker images` is run.

To sucessfully run all the labs the following images are required, although for a given lab you may not need to have them all.

|Docker repo name|Docker tag|Description|VM Based|
|----------------|----------|-----------|--------|
|vrnetlab/vr-vmx | latest   | Juniper vMX image built with vrnetlab |:heavy_check_mark:|
|vrnetlab/vr-vqfx| latest   | Juniper vQFX image built with vrnetlab |:heavy_check_mark:|
|crpd| latest | Juniper cRPD containerized routing protocol daemon | |
|debian|clab | Debian Linux container to simulate servers | |

Many of the images are built with [vrnetlab](https://containerlab.dev/manual/vrnetlab/), a tool to build container images that internally run qemu VMs of network appliances.  This allows us to deploy VM-based network devices, such as Juniper vMX and vQFX, from docker/containerlab.

### Scripts

Helper scripts are included to ease running the labs.

|Name|Description|
|----|-----------|
|add_fqdn_hosts.py|Adds entries in /etc/hosts for all lab nodes, stripping the clab prefix so we can use short names (like 'leaf1') to connect.|
|add_junos_user.py|Adds a new JunOS user to all discovered vQFX/vMX nodes, with a SSH public key for authentication.  Run after deploying a lab to allow homer to connect and add the remaining config.|
|save_junos_configs.py|Saves JunOS configurations from discovered lab nodes.|

Individual labs may also include specific helper-scripts, for instance to configure Linux networking in containers where required.

### Folders

Each of the directories under 'labs' typically contain the following:

|Name|Description|
|----|-----------|
|README|Documentation on the specific lab, notes, instructions etc.|
|Containerlab topology file|YAML file to instantiate the lab with `clab deploy -t`|
|homer_public sub-directory|Root 'public' directory for homer, containing 'config' and 'templates' directories.  When using a particular lab homer's `config.yaml` should point to this directory for that lab.|
|saved_configs<img width=300/>|Saved configuration of fully configured lab nodes for reference.|


### Resources

VM-based labs are resource-heavy, given the number of VMs in total that are spun up.  Depeneding on the lab up to 64GB of RAM may be needed.  

### Installation

To get your system set up to run the labs see [Getting Started](getting_started.md).
