# Copyright 2018-2022 gordonb3 <gordon@bosvangennip.nl>
#
# $Id$

EAPI="7"

DESCRIPTION="Virtual for Bubba Version"
SLOT="0/${PV}"
KEYWORDS=""
IUSE="systemd"

RDEPEND="
	!systemd? (
		app-admin/bubbagen:0/${PV}
	)
	systemd? (
		app-admin/bubbagen:0/${PV}.5
	)
"
