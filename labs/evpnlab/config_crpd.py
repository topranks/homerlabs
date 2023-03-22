#!/usr/bin/python3

import yaml
import os
import subprocess
import argparse
import ipaddress

parser = argparse.ArgumentParser()
parser.add_argument('-p', '--public', help='Path to Homer public dir', default="homer_public")
args = parser.parse_args()


def main():
    """ Adds IP addressing and other config elements to Linux cRPD containers 

    Uses structure same as the interface templates for VM-based JunOS nodes, i.e.
    looks for a 'links' section in the homer sites.yaml file, and expects links to 
    be defined as follows:

    - nodes:
        CORE1: "eth2"
        SPINE1: "xe-0/0/3"
      v4_prefix: "100.64.1.0/31"

    This script will derive the correct iproute2 commands to config the crpd side of 
    any link defined this way.
    """

    with open(f"{args.public}/config/sites.yaml", 'r') as yaml_file:
        sites = yaml.safe_load(yaml_file.read())

    clab_devs = get_clab_juniper()
    for site_name, site_conf in sites.items():
        for link in site_conf['links']:
            # Sort node names so we always get same order as used in templates
            sorted_nodes = list(link['nodes'].keys())
            sorted_nodes.sort()
            sorted_nodes.reverse()
            for index, node in enumerate(sorted_nodes):
                if node.lower() in clab_devs and clab_devs[node.lower()]['kind'] == "crpd":
                    clab_dev = clab_devs[node.lower()]
                    int_name = link['nodes'][node]
                    if "v4_prefix" in link:
                        v4_pfx = link['v4_prefix']
                        ip_addr = f"{ipaddress.ip_network(v4_pfx)[index]}/{ipaddress.ip_network(v4_pfx).prefixlen}"
                        conf_command = f"sudo ip netns exec {clab_dev['container']} ip addr add {ip_addr} dev {int_name}"
                        os.system(conf_command)
                        print(conf_command)


def get_clab_juniper():
    """ Gets detail of running clab nodes by running clab inspect and parsing output """

    devices = {}
    labname = ""
    clab_juniper = subprocess.getoutput("sudo clab inspect -a | egrep 'vqfx|vmx|crpd'")
    for line in clab_juniper.split('\n'):
        split_line = line.split()
        if len(split_line) == 21:
            # Line has lab name in it
            labname = split_line[5]
        nodename = split_line[-14].split("-")[-1].lower()
        kind = split_line[-8]
        ip = split_line[-4].split("/")[0]

        devices[nodename] = {
            "kind": kind,
            "container": split_line[-14],
            "ip": ip
        }

    return devices


if __name__=="__main__":
    main()

