#!/usr/bin/python3

import ipaddress
import yaml

def main():
    with open('homer_public/config/sites.yaml', 'r') as myfile:
        sites = yaml.safe_load(myfile.read())

    for device_name, device_conf in sites['dnslab']['devices'].items():
        namespace = f"clab-dnslab-{device_name.lower()}"
        print(f"ip netns exec {namespace} ip addr add {device_conf['loopback']}/32 dev lo")

    print()

    for link in sites['dnslab']['links']:
        nodes = list(link['nodes'].keys())
        interfaces = list(link['nodes'].values())
        ip_net = ipaddress.ip_network(link['v4_prefix'])
        for index in [0, 1]:
            namespace = f"clab-dnslab-{nodes[index].lower()}"
            ip = ipaddress.ip_interface(f"{ip_net[index]}/{ip_net.prefixlen}")
            interface = interfaces[index]
            print(f"ip netns exec {namespace} ip addr add {ip} dev {interface}")


if __name__ == "__main__":
    main()


