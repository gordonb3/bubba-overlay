# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/b/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

DEPEND="
	dev-libs/glib
	dev-libs/libeutils
	dev-libs/libnl
	dev-libs/libsigc++
	dev-libs/popt
"

RDEPEND="${DEPEND}
"



src_prepare() {
	epatch ${FILESDIR}/${PF}.patch
}

src_compile() {
        emake DESTDIR="${ED}"
}

src_install() {
	exeinto /usr/sbin
	doexe bubba-networkmanager

	exeinto /usr/bin/
	doexe bubba-networkmanager-cli

	insinto /etc/bubba
	newins examplecfg/nmconfig networkmanager.conf

	insinto /usr/share/${PN}
	doins tz-lc.txt

	dodoc debian/changelog debian/copyright
}


