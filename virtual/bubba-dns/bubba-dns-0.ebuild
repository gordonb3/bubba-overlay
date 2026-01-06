# Copyright 2025 gordonb3 <gordon@bosvangennip.nl>
#
# $Id$

EAPI="8"

DESCRIPTION="Virtual for Bubba DNS and DHCP services"
SLOT="0/${PV}"
KEYWORDS="~arm ~ppc"

RDEPEND="|| (
		net-dns/dnsmasq
		net-dns/pi-hole
	)"
