# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/openssl/openssl-1.0.2-r1.ebuild,v 1.2 2015/01/28 19:35:28 mgorny Exp $

EAPI="4"

inherit eutils

MY_P=${P/_*/}
DESCRIPTION="The Bubba meta package"
HOMEPAGE="https://github.com/gordonb3/bubba-overlay"
SRC_URI=""
LICENSE="GPL-3+"
SLOT="0"
IUSE=""

# required by Portage, because we have no SRC_URI...
S="${WORKDIR}"


RDEPEND="
	sys-power/bubba-buttond
"


# A bit of trickery. This package checks for the current package to
# be installed because it should not be installed on other systems.
PDEPEND="
	=sys-apps/sysvinit-2.88_pre150625
"

src_install() {
        dodir "/opt/bubba/etc"
	echo ${MY_P} > ${D}/etc/bubba/bubba.version
}
