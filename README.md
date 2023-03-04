# homerlabs
Virtual networking labs built with containerlab, configured with homer.

## Overview

This repo contains various virtual networking labs, defined in [containerlab](https://containerlab.srlinux.dev/) topology files and  [homer](https://doc.wikimedia.org/homer/master/introduction.html) device data/template folders.

The files for each lab are saved in a different folder in this repo.  Users can change to that directory, instantiate the virtual devices with 'clab deploy', then configure them with homer.

## Labs

The following labs are currently available.

|Name|Description|
|----|-----------|
|[evpnlab](evpnlab/README.md)|Basic Clos with vQFX running EVPN/VXLAN|
|[eqiadlab](eqiadlab/README.md)|Same as evpnlab with two vMX added to represent core routers|
|[esilab](esilab/READMET.md)|Same as eqiadlab but with automation for ESI-LAG off two leaf switches|

## How it works

Containerlab is a framework which allows us to spin up virtual network topologies with docker containers.  A YAML file is used to define the various nodes to deploy, and the links between them.

### Images

To instantiate a lab we need the clab topology file, as well as a working docker subsystem on the local host.  The container images referenced in the clab file should be available on the local host.

To sucessfully run every lab the following images should be present:

|Docker repo name|Docker tag|Description|VM Based|
|----------------|----------|-----------|--------|
|vrnetlab/vr-vmx | latest   | Juniper vMX image built with vrnetlab |:heavy_check_mark:|
|vrnetlab/vr-vqfx| latest   | Juniper vQFX image built with vrnetlab |:heavy_check_mark:|
|debian|clab | Debian Linux container to simulate servers | |

Many of the images are built with [vrnetlab](https://containerlab.dev/manual/vrnetlab/), a tool to build container images that internally run qemu VMs of network appliances.  This allows us to deploy VM-based network devices, such as Juniper vMX and vQFX, from docker/containerlab.

Specific images can be aliased to the required names with something like
    
    docker tag vrnetlab/vr-vmx:21.2R1.10 vrnetlab/vr-vmx:latest

### Scripts

Helper scripts are included with some of the labs.  These are designed to be run after deploying the virtual nodes, and add what we need to sucessfully configure them from homer.

### Resources

Many of the labs are resource-heavy, given the number of VMs in total that are spun up.  Depeneding on the lab up to 64GB of RAM may be needed.  

### Installation

To get your system set up to run the labs see [Getting Started](getting_started.md).
