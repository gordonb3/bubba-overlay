# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
#
# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Add openjdk-bin (Debian build icedtea-bin for armel) as possible JDK provider
#
# $Id$

EAPI="6"

DESCRIPTION="Virtual for Bubba Version"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="systemd"

RDEPEND="~app-admin/bubba-1.8
	systemd? (
		>=app-admin/bubba-1.8.5
	)
	!systemd? (
		<app-admin/bubba-1.8.5
	)
"
