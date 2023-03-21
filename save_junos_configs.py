#!/usr/bin/python3

import os
import sys
import json
import yaml
import argparse
from pathlib import Path

from jnpr.junos import Device
from jnpr.junos.utils.config import Config
from jnpr.junos.exception import ConnectError

parser = argparse.ArgumentParser()
parser.add_argument('-s', '--sshconfig', help='SSH config file', default='/root/.ssh/config')
parser.add_argument('-d', '--outputdir', help='Directory for saved config files', default='/root/wmf-clab')
parser.add_argument('-c', '--clab_file', help='Location of containerlab topology file.', default='/root/wmf-clab/output/wmf-clab.yaml')
args = parser.parse_args()

def main():
    Path(f"{args.outputdir}/crpd_configs").mkdir(exist_ok=True, parents=True)

    with open(args.clab_file, 'r') as clab_file:
        clab = yaml.safe_load(clab_file)

    for node_name, node_conf in clab['topology']['nodes'].items():
        if node_conf['kind'] == "crpd":
            print(f"Connecting to {node_name}... ", end="", flush=True)
            junos_dev = get_junos_dev(node_name)
            config = junos_dev.rpc.get_config(options={'format':'json'})
            with open(f"{args.outputdir}/crpd_configs/{node_name}.json", "w") as config_file:
                config_file.write(json.dumps(config))
            print("saved ok.")


def get_junos_dev(dev_name):
    # Initiates NETCONF session to router
    try:
        device = Device(dev_name, username=os.getlogin(), ssh_config=args.sshconfig, port=22)
        device.open()
    except ConnectError as err:
        print(f"Cannot connect to device: {err}")
        sys.exit(1)

    # Get config object
    device.bind(config=Config)

    return device


if __name__ == '__main__':
    main()

