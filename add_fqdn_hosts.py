#!/usr/bin/python3

import os

def main():
    """ Adds FQDNs for clab devices to /etc/hosts"""

    new_file = open('/tmp/new_hosts', 'w')

    with open('/etc/hosts', 'r') as hostsfile:
        for line in hostsfile.readlines():
            line_strip = line.strip()
            if "lab-" in line and not ("START" in line or "END" in line):
                description = line.split("#")[-1]
                host_data = line.split("#")[0]
                device = host_data.split()[1].split("-")[-1]
                new_file.write(f"{host_data} {device}\t#{description}")
            else:
                new_file.write(line)

    new_file.close()

    os.system('rm -vf /etc/hosts && mv -v /tmp/new_hosts /etc/hosts')

if __name__=="__main__":
    main()

