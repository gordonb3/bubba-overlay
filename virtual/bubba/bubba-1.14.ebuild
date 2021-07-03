# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
#
# $Id$

EAPI="6"

DESCRIPTION="Virtual for Bubba Version"
SLOT="0/${PV}"
KEYWORDS="~arm ~ppc"
IUSE="systemd"

RDEPEND="
	!systemd? (
		app-admin/bubbagen:0/${PV}
	)
	systemd? (
		app-admin/bubbagen:0/${PV}.5
	)
"
