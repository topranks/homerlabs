# eqiadlab

![eqiadlab topology](https://raw.githubusercontent.com/topranks/homerlabs/main/labs/eqiadlab/diagram.png)

This is a containerlab topology based on my previous [evpnlab](../evpnlab), but with two vMX devices added to simulate core/border routers.


#### TODO

Core router config is very basic.  Need to add unicast BGP peerings to the Spine layer, IBGP between them etc.


#### Running the lab

Users should have installed everything as described in [getting started](../../getting_started.md), and be familiar with the generic steps described there to run labs.  Below is a high-level overview:

##### 1. Change to the lab directory and init the lab with containerlab:
```
cd ~/homerlabs/labs/eqiadlab
sudo clab deploy -t eqiadlab.yaml
```

vQFX devices take a few minutes to start up, so wait 5-10 minutes before proceeding.

##### 2. Add entries for lab nodes to your local host file:
```
cd ~/homerlabs
sudo ./add_fqdn_hosts.py
```

##### 3. Add local user and SSH key to the vQFX devices:
```
sudo ./add_junos_user.py --user homer --pubkey ~/.ssh/homerlabs_ed25519.pub 
```

#### 4. Add user config to vMX devices manually

The default user/pass for the vMX isn't clear, so we need to add our user manually.  For example for core1 (make sure to use your own SSH public key not the one shown below):
```
cathal@officepc:~$ sudo ip netns exec clab-eqiadlab-core1 telnet localhost 5000 
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.

root@:~ # cli
root@core1> 

root@core1> configure 
Entering configuration mode

[edit]
root@core1# set system login user homer class super-user 

[edit]
root@core1# set system login user homer authentication ssh-ed25519 "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFyIygMcbB1dZpJodQCTd1kqhXWIWu2KKjztnxyq6KCX cathal@officepc" 

[edit]
root@core1# commit 
commit complete

[edit]
root@core1# exit 
Exiting configuration mode

root@core1> 
```

We can exit the telnet session with CTRL + ], and then typing quit:
```
telnet> quit
Connection closed.
```

After which we should be able to SSH:
```
cathal@officepc:~$ ssh -i ~/.ssh/homerlabs_ed25519 homer@core1
Last login: Tue Mar 21 23:31:31 2023 from 10.0.0.2
--- JUNOS 21.2R1.10 Kernel 64-bit  JNPR-12.1-20210529.2f59a40_buil
homer@core1> 
```


##### 5. Configure the JunOS devices with Homer:
```
homer '*' commit "configure eqiadlab"
```

##### 5. Configure server container IP addressing

Run the `config_servers.sh` shell script from the lab dir to add basic IP configuration to the containers simulating end servers:
```
cathal@officepc:~/homerlabs/labs/eqiadlab$ ./config_servers.sh 
+ sudo ip netns exec clab-eqiadlab-server1 ip addr add 198.18.100.11/24 dev eth1
+ sudo ip netns exec clab-eqiadlab-server1 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-eqiadlab-server1 ip addr add 2001:0470:6a7f:0100::11/64 dev eth1
+ sudo ip netns exec clab-eqiadlab-server1 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254
+ sudo ip netns exec clab-eqiadlab-server2 ip addr add 198.18.100.12/24 dev eth1
+ sudo ip netns exec clab-eqiadlab-server2 ip route add 198.18.0.0/16 via 198.18.100.254
+ sudo ip netns exec clab-eqiadlab-server2 ip addr add 2001:0470:6a7f:0100::12/64 dev eth1
+ sudo ip netns exec clab-eqiadlab-server2 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0100::254
+ sudo ip netns exec clab-eqiadlab-server3 ip addr add 198.18.101.13/24 dev eth1
+ sudo ip netns exec clab-eqiadlab-server3 ip route add 198.18.0.0/16 via 198.18.101.254
+ sudo ip netns exec clab-eqiadlab-server3 ip addr add 2001:0470:6a7f:0101::13/64 dev eth1
+ sudo ip netns exec clab-eqiadlab-server3 ip route add 2001:0470:6a7f:0100::/60 via 2001:0470:6a7f:0101::254
```
