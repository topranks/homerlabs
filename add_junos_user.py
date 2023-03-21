#!/usr/bin/python3

from jnpr.junos import Device
from jnpr.junos.utils.config import Config
from jnpr.junos.exception import ConnectError
from jnpr.junos.utils.start_shell import StartShell

import argparse
import os
import subprocess

import warnings
warnings.filterwarnings(action='ignore',module='.*paramiko.*')

from cryptography.utils import CryptographyDeprecationWarning
with warnings.catch_warnings():
    warnings.filterwarnings('ignore', category=CryptographyDeprecationWarning)
    import paramiko

from time import sleep
from pprintpp import pprint as pp

parser = argparse.ArgumentParser()
parser.add_argument('-u', '--user', help='User to add to devices', default='homer')
parser.add_argument('-p', '--pubkey', help='Path to SSH public key', default='~/.ssh/homerlabs_ed25519.pub')
parser.add_argument('-s', '--sshconf', help='Path to SSH config file to use when connecting', default='~/.ssh/config_homer')
args = parser.parse_args()

def main():
    """ Adds a user with SSH key to vqfx devices found by running clab inspect """

    with open(args.pubkey, 'r') as keyfile:
        pubkey = keyfile.readline().rstrip('\n')

    devices = get_clab_juniper()
    for device_name, dev_vars in devices.items():
        add_user_config(device_name, dev_vars, pubkey)


def get_clab_juniper():
    devices = {}
    labname = ""
    clab_juniper = subprocess.getoutput("sudo clab inspect -a | egrep 'vqfx|vmx'")
    for line in clab_juniper.split('\n'):
        split_line = line.split()
        if len(split_line) == 21:
            # Line has lab name in it
            labname = split_line[5]
        nodename = split_line[-14].removeprefix(f"clab-{labname}-")
        kind = split_line[-8]
        ip = split_line[-4].split("/")[0]

        devices[nodename] = {
            "kind": kind,
            "ip": ip            
        }

    return devices


def add_user_config(dev_name, dev_vars, pubkey):
    """ Adds configured user and ssh key using CLI to allow key-based SSH for Homer """

    print(f"Trying to conenct to {dev_name} at {dev_vars['ip']}... ", end="", flush=True)
    if dev_vars['kind'] == "vr-vqfx":
        device = Device(host=f"{dev_vars['ip']}", port=22, user="root", password="Juniper")
    else:
        # device = Device(host=f"{dev_vars['ip']}", port=22, user="vmx_user", password="vmx_password")
        print(f"{dev_name} is vMX - add from docker shell - don't know default password!")
        return

    ss = StartShell(device)
    ss.open()
    print("connected.")

    ret_val, lines = ss.run('cli')
    getprompt(lines)
    print(f"Adding user {args.user} with CLI... ", end="", flush=True)
    ret_val, lines = ss.run('configure')
    getprompt(lines)
    ret_val, lines = ss.run(f"set system login user {args.user} class super-user")
    getprompt(lines)
    ssh_key_type = pubkey.split()[0]
    ret_val, lines = ss.run(f"set system login user {args.user} authentication {ssh_key_type} \"{pubkey}\"")
    getprompt(lines)
    ret_val, lines = ss.run("commit")
    getprompt(lines)
    ret_val, lines = ss.run("exit")
    getprompt(lines)
    print("done.")

    device.close()


def getprompt(lines):
    """ Returns when it gets CLI promot, if none found exits with error. """
    for line in lines.split('\n'):
        if line.endswith("> ") or line.endswith("# "):
            return line

    print(f"Never got prompt - quitting - output receieved:\n{lines}")
    sys.exit(1)


def get_junos_dev(dev_name):
    # Initiates NETCONF session to router
    try:
        device = Device(dev_name, username=args.user, ssh_config=args.sshconfig, port=22)
        device.open()
    except ConnectError as err:
        print(f"Cannot connect to device: {err}")
        sys.exit(1)

    # Get config object
    device.bind(config=Config)

    return device


if __name__ == '__main__':
    main()
