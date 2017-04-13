# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils perl-module

DESCRIPTION="Perl bindig for Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/libb/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""

DEPEND="
	dev-lang/perl:=
	dev-libs/libbubba-info
"

RDEPEND="${DEPEND}
"

src_prepare() {
	sed "s/^\(\s*.ABSTRACT\)_FROM.*$/\1       => 'Perl extension for querying Bubba platform information',/" -i Makefile.PL

}


src_configure() {
	perl Makefile.PL
}

src_compile() {
	emake DESTDIR=${ED}
}

src_install() {
	emake DESTDIR=${ED} INSTALLDIRS=vendor install

	dodoc debian/changelog debian/copyright

	
}


