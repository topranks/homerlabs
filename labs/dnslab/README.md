# dnslab

This was a quick one just to test equalizing the BGP paths betwen anycast routes announced to LEAF switches, and those announced directly to Core Routers.

TL;DR the "Anycast4" BGP group needs to have "multipath multiple-as;" configured in order for the config to work.  That group already has config to pre-pend inbound by 1 ASN, so it is already creating a situation where ther are two ASNs on the anycast routes, which matches those learnt from the Spines.  But the ASNs themselves are different, so "mutlipath multiple-as" is needed.  If this is applied to the 'Switch' and 'AnycastX' BGP groups only equal routes from those groups will be considered, so this will not end up adding routes learnt from remote confederations to the anycast / next-hop group.
