# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils perl-module

DESCRIPTION="Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/libb/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

DEPEND=""

RDEPEND="${DEPEND}
	dev-libs/libbubba-info
"


src_prepare() {
	perl Makefile.PL
}

src_compile() {
	emake DESTDIR=${ED}
}

src_install() {
	emake DESTDIR=${ED} install

	dodoc debian/changelog debian/copyright

	
}


