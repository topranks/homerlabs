#!/bin/python3

import ipaddress

import yaml
import argparse

from collections import defaultdict

parser = argparse.ArgumentParser()
parser.add_argument('-t', '--lab_conf', help='CLAB lab_conf file', required=True)
args = parser.parse_args()

V4_BLOCK = "198.18.0.0/16"
V6_PREFIX = ""

FIXED_ASN = {
    "r2": "65000",
    "r3": "65000"
}

def main():
    with open(args.lab_conf, 'r') as myfile:
        lab_conf = yaml.safe_load(myfile)

    config_lines = defaultdict(set)

    lab_name = lab_conf['name']
    v4_prefixes = ipaddress.ip_network(V4_BLOCK).subnets(new_prefix=31)
    for link in lab_conf['topology']['links']:
        v4_prefix = next(v4_prefixes)
        for index, r_int in enumerate(link['endpoints']):
            netns = f"clab-{lab_name}-{r_int.split(':')[0]}"
            interface = r_int.split(':')[1]
            ip_addr = f"{v4_prefix[index]}/{v4_prefix.prefixlen}"
#            print(f"sudo ip netns exec {netns} ip addr add {ip_addr} dev {interface}")
            local_router = r_int.split(":")[0]
            r_index = local_router[-1]

            local_asn = FIXED_ASN[local_router] if local_router in FIXED_ASN else f"6452{r_index}"
            config_lines[r_index].add(f"set routing-options router-id {r_index}.{r_index}.{r_index}.{r_index}")
            config_lines[r_index].add(f"set routing-options autonomous-system {local_asn}")

            far_side_ip = v4_prefix[1] if index == 0 else v4_prefix[0]

            far_side_int = link['endpoints'][1] if index == 0 else link['endpoints'][0]
            far_side_router = far_side_int.split(":")[0]
            peer_asn = FIXED_ASN[far_side_router] if far_side_router in FIXED_ASN else f"6452{far_side_router[-1]}"

            bgp_group = "IBGP" if peer_asn == local_asn else "EBGP"

            config_lines[r_index].add(f"set protocols bgp log-updown")
            config_lines[r_index].add(f"set protocols bgp group {bgp_group} neighbor {far_side_ip} description {far_side_router.upper()}")
            config_lines[r_index].add(f"set protocols bgp group {bgp_group} neighbor {far_side_ip} peer-as {peer_asn}")


    for router, config_list in config_lines.items():
        print(f"R{router}")
        for line in sorted(config_list):
            print(line)
        print()
            

if __name__=="__main__":
    main()

