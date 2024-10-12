Simple lab to test v6 forwarding

Seems to be that the individual ipv6 forwarding sysctl's for interfaces do nothing.

We observed this in work but I wanted to test out so built this simple lab, also wanted to validate if the use of Linux VRF had any bearing on this.

Subsequently found the below which seems to refer to it:

https://linux.die.net/HOWTO/Linux+IPv6-HOWTO/proc-sys-net-ipv6..html

TL;DR net.ipv6.conf.all.forwarding must be set to 1 for forwarding to work for IPv6, and the individual controls have no effect at all.
