# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/libb/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

DEPEND=""

RDEPEND="${DEPEND}"



src_prepare() {
	sed -i "s/libtool --mode/libtool --tag=CC --mode/" Makefile
}


src_install() {
	make DESTDIR=${ED} install
	dodoc debian/changelog debian/copyright
}
