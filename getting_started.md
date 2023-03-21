# Getting Started

#### Notes

The lab is designed to be run on Linux.  Some of the Juniper virtual devices run as QEMU virtual machines, so it is better to run on bare metal.  It should in theory work in a VM, however, if nested virtualization is enabled.

### Steps

#### 1. Install Docker

Installer docker using [their instructions](https://docs.docker.com/engine/install/).


#### 2. Create docker container image that runs the vQFX VMs

Firstly you'll need to have Juniper's [vQFX](https://www.juniper.net/us/en/dm/free-vqfx10000-software.html) images downloaded.  The vQFX runs as two separate virtual machines, one which takes care of packet forwarding (PFE) and one that manages the device's control plane (vCP).

To run vQFX in containerlab we need to wrap the VM execution in a container that can be run with docker (see [here](https://containerlab.dev/manual/vrnetlab/)).  Once you have the vQFX qemu images you can create this container by using [vrnetlab](https://github.com/vrnetlab/vrnetlab) following the instructions below:

[Juniper vQFX and Containerlab Tutorial](https://www.theasciiconstruct.com/post/junos-vqfx-containerlab/)

The vQFX image should be alias'ed to vrnetlab/vr-vqfx:latest, as that is what the clab topology files will reference.  For example:

    docker tag vrnetlab/vr-vqfx:20.2R1.10 vrnetlab/vr-vqfx:latest


#### 3. Create docker container image that runs the vMX VMs

Assuming one already has requried Juniper vMX images we folow a similar process to above to create a vMX container image with vrnetlab.

Like the vQFX there are two VMs, and two qeumu images, for the vMX.  However Juniper typcically distribute this as a single tar file, for instance called 'vmx-bundle-21.2R1.10.tgz'.  This is what we place in the 'vmx' directory of vrnetlab, rather than the two qcow files like we did for vQFX.

With the tgz file in the vrnetlab 'vmx' directory just run make to create the docker image.  Note it takes some time as it boots the vMX before saving, this is because the vMX takes longer to initialise on first boot, and doing it before saving the docker image saves that wait every time we initialize a container from it.

The vMX image should be alias'ed to 'vrnetlab/vr-vmx:latest', for example:

    docker tag vrnetlab/vr-vmx:21.2R1.10 vrnetlab/vr-vmx:latest


#### 4. Create docker container to simulate connected servers

Each of the LEAF switches in the lab has a test server connected.  These are simulated using a docker container.  Any kind of Linux container will work, I typically use "debian:stable-slim".  

Given this is a networking lab it helps to have some networking tools available inside the container.  So I typically run a shell in the container, install the tools I need, then save the updated container as a new image which the lab runs:
```
docker run -it debian:stable-slim bash
```
Then inside the container install whatever packages might be useful:
```
apt update
apt install tcpdump iproute2 iputils-ping mtr-tiny arping traceroute nmap netcat tshark iptables iperf iperf3
```

When the install is finished open another shell on the same machine, and commit the running container as a new image.  We tag it as debian:clab which is what the lab topology files reference:
```
root@debiantemp:~# docker ps
CONTAINER ID   IMAGE                COMMAND   CREATED         STATUS         PORTS     NAMES
226ce85f24f4   debian:stable-slim   "bash"    7 minutes ago   Up 7 minutes             naughty_goldstine
root@debiantemp:~# 
root@debiantemp:~# docker commit 226ce85f24f4 debian:clab 
sha256:3229de033420148cbbbbce37d5f1415719c173916bea40563a0e5873e483ca08
root@debiantemp:~# 
```

#### 5. Add CRPd image

For labs that require Juniper's cRPD container-based routing-process daemon we need to add the docker image Juniper distribute to the local docker.

Download the cRPD tgz file and add it as follows:

    docker load -i junos-routing-crpd-docker-19.4R1.10.tgz

We want to alias the added image to 'crpd:latest' then:

    docker tag hub.juniper.net/routing/crpd:19.4R1.10 crpd:latest


#### 6. Verify all required images are presnet.

If you've followed the steps you should now have several docker images on the local system, run 'docker images' to verify everything looks ok.

You'll have several more than shown below, but all 4 should be present with the same 'repository' and 'tag' so the names used in the lab YAML topologies will work:

    root@officepc:~# docker images
    REPOSITORY                     TAG             IMAGE ID       CREATED        SIZE
    vrnetlab/vr-vmx                latest          e9a3a0781c03   2 weeks ago    4.32GB
    vrnetlab/vr-vqfx               latest          c4402f8ebcbd   5 weeks ago    1.83GB
    debian                         clab            1a8ce1b943bf   3 months ago   175MB
    crpd                           latest          5b6acdd96efb   3 years ago    320MB


#### 7. Install containerlab

Follow the instructions to [install containerlab](https://containerlab.dev/install/)


#### 8. Clone this repo

Clone this repo to your machine, I normally do this in my home directory:
```
git clone https://github.com/topranks/homerlabs.git
```

#### 9. Install Homer 

Install WMF Homer and Ansible using pip:
```
pip3 install homer ansible
```

Ansible isn't used in this project, however the Ansible-provided 'ipaddr' filter is used in some of the Jinja2 templates.  This is a very useful tool when using Homer with only YAML files (i.e. without the Netbox plugin or similar to transform data in advance).

TODO: Create fork of Homer which includes the ipaddr module

For now you'll need to change Homer to import the ipaddr module and make it usable in templates.  To do so locate the "tempaltes.py" Homer file on your system and add this to the top:

```python
from ansible_collections.ansible.utils.plugins.filter import ipaddr
```

And then add this line at the end of the __init__ function in the Renderer class:

```python
        self._env.filters.update(ipaddr.FilterModule().filters())
```


#### 10. Generate SSH keypair to use with labs

Passwordless SSH is used by Homer using SSH keys when connecting to lab devices.

To make this go smoothly we create an SSH keypair for use with labs:

```
mkdir -p ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/homerlabs_ed25519
```

You can use a passphrase or not.  I usually don't because this is just used for a local junk lab, but remember never to use this key on any important systems.  In production it is vital strong passphrases are used on all ssh keys.

#### 11. Create SSH config file to use with homer

We need to provide homer with an [https://www.cyberciti.biz/faq/create-ssh-config-file-on-linux-unix/](ssh config) file to use when connecting to routers.

Create a new file at `~/.ssh/config_homer` with your favourite editor, for instance vim:

    vim ~/.ssh/config_homer

Now add the following contents:
```
Host *
    IdentityFile ~/.ssh/homerlabs_ed25519
```

#### 12. Add homer configuration file

You'll need to create a homer configuration file at **/etc/homer/config.yaml**, contents should be similar to below.  The two main items to pay attention to here are:

|Variable path|Description|
|-------------|-----------|
|transports/username|Username that Homer will use when initiating SSH to devices, a JunOS user needs to be set up on the devices with the same name|
|tansports/ssh_config|Path of the SSH config file created in the last step|
|base_paths/public|This var needs to be changed when running different labs.  It needs to point at the appropriate 'homer_public' dir from this repo for the given lab.  This directory contains all the YAML config and Jinja templates to automate the config for a particular lab.  Path should be absolute, bash shortcuts like '~' for home directory don't work.|

```yaml
base_paths:
  # Path of Homer public repo files for given labs, for instance evpnlab path below:
  public: /home/cathal/homerlabs/labs/evpnlab/homer_public
  # Base path for the output files generated on the 'generate' action. The directory will be cleaned from all '*.out' files.
  output: /tmp

# Transpors configuration. [optional]
transports:
  username: homer
  ssh_config: ~/.ssh/config_homer
  junos:
    ignore_warning:
      - statement must contain additional statements
      - statement has no contents
      - config will be applied to ports
```


#### 13. Run labs

At this point you should be able to run any of the labs.  Please see the README file for each lab for detailed instructions, in many cases there are extra steps needed than what is shown here.

The general way to run a given lab is to change to that directory and run 'clab deploy', for instance:
```
cathal@officepc:~/homerlabs/labs/evpnlab$ sudo clab deploy -t evpnlab.yaml
INFO[0000] Containerlab v0.38.0 started
INFO[0000] Parsing & checking topology file: evpnlab.yaml
INFO[0000] Creating lab directory: /home/cathal/homerlabs/labs/evpnlab/clab-evpnlab
INFO[0000] Creating docker network: Name="evpnlab", IPv4Subnet="172.20.20.0/24", IPv6Subnet="2001:172:20:20::/64", MTU="1500"
INFO[0001] Creating container: "spine2"
INFO[0001] Creating container: "server1"
INFO[0001] Creating container: "server3"
INFO[0001] Creating container: "server2"
INFO[0001] Creating container: "spine1"
INFO[0001] Creating container: "leaf1"
INFO[0001] Creating container: "leaf2"
INFO[0001] Creating container: "leaf3"
INFO[0002] Creating virtual wire: server3:eth1 <--> leaf3:eth3
INFO[0002] Creating virtual wire: server1:eth1 <--> leaf1:eth3
INFO[0002] Creating virtual wire: spine2:eth2 <--> leaf2:eth2
INFO[0002] Creating virtual wire: spine2:eth1 <--> leaf1:eth2
INFO[0002] Creating virtual wire: spine2:eth3 <--> leaf3:eth2
INFO[0002] Creating virtual wire: server2:eth1 <--> leaf2:eth3
INFO[0003] Creating virtual wire: spine1:eth2 <--> leaf2:eth1
INFO[0003] Creating virtual wire: spine1:eth1 <--> leaf1:eth1
INFO[0003] Creating virtual wire: spine1:eth3 <--> leaf3:eth1
INFO[0004] Adding containerlab host entries to /etc/hosts file
+---+----------------------+--------------+----------------------------+---------+---------+----------------+----------------------+
| # |         Name         | Container ID |           Image            |  Kind   |  State  |  IPv4 Address  |     IPv6 Address     |
+---+----------------------+--------------+----------------------------+---------+---------+----------------+----------------------+
| 1 | clab-evpnlab-leaf1   | 9cd57dca039d | vrnetlab/vr-vqfx:20.2R1.10 | vr-vqfx | running | 172.20.20.6/24 | 2001:172:20:20::6/64 |
| 2 | clab-evpnlab-leaf2   | 2725c5abf024 | vrnetlab/vr-vqfx:20.2R1.10 | vr-vqfx | running | 172.20.20.8/24 | 2001:172:20:20::8/64 |
| 3 | clab-evpnlab-leaf3   | 20cbd4bc588b | vrnetlab/vr-vqfx:20.2R1.10 | vr-vqfx | running | 172.20.20.4/24 | 2001:172:20:20::4/64 |
| 4 | clab-evpnlab-server1 | a7027232d63e | debian:clab                | linux   | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
| 5 | clab-evpnlab-server2 | a2ad6d522337 | debian:clab                | linux   | running | 172.20.20.5/24 | 2001:172:20:20::5/64 |
| 6 | clab-evpnlab-server3 | d9ffcc52aed5 | debian:clab                | linux   | running | 172.20.20.7/24 | 2001:172:20:20::7/64 |
| 7 | clab-evpnlab-spine1  | b6fb401f10d8 | vrnetlab/vr-vqfx:20.2R1.10 | vr-vqfx | running | 172.20.20.9/24 | 2001:172:20:20::9/64 |
| 8 | clab-evpnlab-spine2  | d7aaf55cf8c7 | vrnetlab/vr-vqfx:20.2R1.10 | vr-vqfx | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
+---+----------------------+--------------+----------------------------+---------+---------+----------------+----------------------+
```

#### 14. Add local hosts file entries for the lab nodes

Containerlab adds all nodes it initates to the local hosts file with the naming convention clab-<labname>-<nodename>.

Typically in the Homer YAML files the nodes are named just with the 'nodename' part of this.  To make the devices reachable from homer using only this short name we can run the invluded `add_fqdn_hosts.py` script as follows:
```
cathal@officepc:~/homerlabs$ sudo ./add_fqdn_hosts.py 
removed '/etc/hosts'
renamed '/tmp/new_hosts' -> '/etc/hosts'
```

#### 15. Add local user to Junos with SSH public key

Before it's possible to use homer to configure virutal Juniper devices we need to add a user to them matching what we configured in the homer config file above.

The included script with this repo, `add_junos_user.py`, will find all VM-based Juniper clab devices, log on using the default username/password, and add a new user and SSH public key.

Run it with 'sudo' as it needs the rights to see all the running docker containers:
```
cathal@officepc:~/homerlabs$ sudo ./add_junos_user.py --user homer --pubkey ~/.ssh/homerlabs_ed25519.pub 
Trying to conenct to leaf1 at 172.20.20.6... connected.
Adding user homer with CLI... done.
Trying to conenct to leaf2 at 172.20.20.8... connected.
Adding user homer with CLI... done.
Trying to conenct to leaf3 at 172.20.20.4... connected.
Adding user homer with CLI... done.
Trying to conenct to spine1 at 172.20.20.9... connected.
Adding user homer with CLI... done.
Trying to conenct to spine2 at 172.20.20.2... connected.
Adding user homer with CLI... done.
```

NOTE: This takes a *long* time.  For some reason the Juniper [StartShell](https://www.juniper.net/documentation/us/en/software/junos-pyez/junos-pyez-developer/topics/task/junos-pyez-program-shell-accessing.html) takes ages to run on the vQFX, at least on my system.  But it works ok, I need to revisit to see why it goes so slow.

When done you should be able to SSH into any of the Juniper devices using the username and ssh key generated earlier, and the short name used in the Homer config files:
```
cathal@officepc:~$ ssh -i ~/.ssh/homerlabs_ed25519 homer@leaf1 
--- JUNOS 19.4R1.10 built 2019-12-19 03:54:05 UTC
{master:0}
homer@vqfx-re> 
```

#### 15. Configure devices using Homer

Once passwordless SSH is running we should be able to push config's homer generates to the devices, for instance:
```
cathal@officepc:~$ homer '*' commit "Configure lab nodes"
INFO:homer.devices:Initialized 5 devices
INFO:homer:Committing config for query * with message: Configure lab nodes
INFO:homer.devices:Matched 5 device(s) for query '*'
INFO:homer:Generating configuration for LEAF1
Configuration diff for LEAF1:

[edit system]
-  host-name vqfx-re;
+  host-name LEAF1;
+  arp {
+      aging-timer 10;
+  }
[edit interfaces]
-   et-0/0/0 {

<--- OUTPUT CUT --->

Type "yes" to commit, "no" to abort.
> yes
INFO:homer.transports.junos:Committing the configuration on SPINE2
INFO:homer:Homer run completed successfully on 5 devices: ['LEAF1', 'LEAF2', 'LEAF3', 'SPINE1', 'SPINE2']
```

Be aware these generalized instructions are just a guide, specific labs may have additional steps to follow so check the README file for each lab you wish to run.
