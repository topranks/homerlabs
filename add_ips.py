#!/bin/python3

import ipaddress

import yaml
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-t', '--lab_conf', help='CLAB lab_conf file', required=True)
args = parser.parse_args()

V4_BLOCK = "198.18.0.0/16"
V6_PREFIX = ""

def main():
    with open(args.lab_conf, 'r') as myfile:
        lab_conf = yaml.safe_load(myfile)

    lab_name = lab_conf['name']
    v4_prefixes = ipaddress.ip_network(V4_BLOCK).subnets(new_prefix=31)
    for link in lab_conf['topology']['links']:
        v4_prefix = next(v4_prefixes)
        for index, r_int in enumerate(link['endpoints']):
            netns = f"clab-{lab_name}-{r_int.split(':')[0]}"
            interface = r_int.split(':')[1]
            ip_addr = f"{v4_prefix[index]}/{v4_prefix.prefixlen}"
            print(f"sudo ip netns exec {netns} ip addr add {ip_addr} dev {interface}")
        print()
            

if __name__=="__main__":
    main()

