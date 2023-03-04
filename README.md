# homerlabs
Virtual networking labs built with containerlab, configured with homer.

## Overview

This repo contains various virtual networking labs, defined as [containerlab](https://containerlab.srlinux.dev/) topology files and  [homer](https://doc.wikimedia.org/homer/master/introduction.html) device data/template folders.

The files for each lab are saved in a different folder in this repo.  Users can change to that directory, instantiate the virtual devices with 'clab deploy', then configure them with homer.

## Labs

The following labs are currently available.

|Name|Description|
|----|-----------|
|[evpnlab](evpnlab/README.md)|Basic Clos with vQFX running EVPN/VXLAN|
|[eqiadlab](eqiadlab/README.md)|Same as evpnlab with two vMX added to represent core routers|
|[esilab](esilab/READMET.md)|Same as eqiadlab but with automation for ESI-LAG off two leaf switches|

## How it works

Containerlab is a framework which allows us to spin up virtual network topologies with docker containers.  A [YAML file](https://containerlab.dev/manual/topo-def-file/) is used to define the various nodes to deploy, and the links between them.

### Images

To instantiate a lab we need the clab topology file, as well as a working docker subsystem on the local host.  Container images referenced in the clab file should be available locally, and show up when `docker images` is run.

To sucessfully run all the labs the following images are required:

|Docker repo name|Docker tag|Description|VM Based|
|----------------|----------|-----------|--------|
|vrnetlab/vr-vmx | latest   | Juniper vMX image built with vrnetlab |:heavy_check_mark:|
|vrnetlab/vr-vqfx| latest   | Juniper vQFX image built with vrnetlab |:heavy_check_mark:|
|debian|clab | Debian Linux container to simulate servers | |

Many of the images are built with [vrnetlab](https://containerlab.dev/manual/vrnetlab/), a tool to build container images that internally run qemu VMs of network appliances.  This allows us to deploy VM-based network devices, such as Juniper vMX and vQFX, from docker/containerlab.

### Scripts

Helper scripts are included with some of the labs.  These are designed to be run after deploying the virtual nodes, and add what the minimum config required to connect to them with homer.

### Folders

Each of the directories under 'labs' typically contain the following:

|Name|Description|
|----|-----------|
|README|Documentation on the specific lab, notes, instructions etc.|
|Containerlab topology file|YAML file to instantiate the lab with `clab deploy -t`|
|homer_public sub-directory|Root 'public' directory for homer, containing 'config' and 'templates' directories.  Homer's config.yaml should point to this when configuring the lab nodes.|
|saved_configs<img width=300/>|Saved configuration of fully configured lab nodes for reference.|


### Resources

VM-based labs are resource-heavy, given the number of VMs in total that are spun up.  Depeneding on the lab up to 64GB of RAM may be needed.  

### Installation

To get your system set up to run the labs see [Getting Started](getting_started.md).
