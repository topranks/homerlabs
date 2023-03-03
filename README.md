# homerlabs
Networking labs based on containerlab, using Homer for configuration

## Overview

This repo contains various virtual networking labs, defined in [containerlab](https://containerlab.srlinux.dev/) topology files and  [Homer](https://doc.wikimedia.org/homer/master/introduction.html) device data/template folders.
The files for each lab are saved in a different folder in this repo.  Users can change to that directory, instantiate the lab with 'clab', and then run Homer to configure the nodes.

## Labs
The following labs are currently available.

## How it works

Containerlab is based on Linux containers/docker.  Docker image names refered in clab topology files need to be available on the local system.  Most of the labs use containers images built with [vrnetlab](https://containerlab.dev/manual/vrnetlab/).  These containers are wrappers on vendor virtual-machine images that simulate various networking platforms.  The images are built to run the required VM(s) when they are initialized within the container.  Given that's the case it's best to run on bare-metal.  Running in a VM may be possible using nest-virtualisation, but it remains untested.

The following docker images / names should be available to the system in order to be able to run any of the labs:

|Docker repo name|Docker tag|Description|VM Based|
|----------------|----------|-----------|--------|
|vrnetlab/vr-vmx | latest   | Juniper vMX image built with vrnetlab |<ul> [x] </ul>|
|vrnetlab/vr-vqfx| latest   | Juniper vQFX image built with vrnetlab |[x]|
|debian|clab | Debian Linux container to simulate servers |[ ]|

cathal@officepc:~/esilab$ sudo docker images 
REPOSITORY           TAG             IMAGE ID       CREATED         SIZE
vrnetlab/vr-vmx      latest          e9a3a0781c03   43 hours ago    4.32GB
vrnetlab/vr-vqfx     latest          c4402f8ebcbd   3 weeks ago     1.83GB
debian               clab            1a8ce1b943bf   2 months ago    175MB

Tag the images you build with these names using something like `docker tag vrnetlab/vr-vmx:21.2R1.10 vrnetlab/vr-vmx:latest`

### Resources
Some of the labs are quite resource-heavy, given the number of VMs in total that are spun up.  

### Installation
