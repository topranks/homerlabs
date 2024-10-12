#!/usr/bin/python3

import ipaddress

def main():
    supernet = ipaddress.ip_network('2001:0bb6:8b70:9e70::/61')
    networks = list(supernet.subnets(new_prefix=64))

    router_commands = ["### R1"]
    host_commands = []
    for i in range(4):
        network = networks[i+1]
        router_commands.append(f"ip netns exec clab-v6_sysctl-r1 ip addr add {network[1]}/64 dev eth{i+1}")
        host_commands.append(f"### H{i+1}")
        host_commands.append(f"ip netns exec clab-v6_sysctl-h{i+1} ip addr add {network[2]}/64 dev eth1")
        host_commands.append(f"ip netns exec clab-v6_sysctl-h{i+1} ip -6 route add {supernet} via {network[1]}")
        host_commands.append("")

    for command in router_commands:
        print(command)
    print()
    for command in host_commands:
        print(command)
        
        


if __name__=="__main__":
    main()
