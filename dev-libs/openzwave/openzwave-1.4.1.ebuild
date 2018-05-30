# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Free software library that interfaces with selected Z-Wave PC controllers"
HOMEPAGE="http://www.openzwave.net/"

SRC_URI="http://old.openzwave.com/downloads/${PF}.tar.gz"
RESTRICT="mirror"
LICENSE="GPL-3 Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~x86"
IUSE="-examples -htmldoc"

DEPEND="htmldoc? ( app-doc/doxygen  media-gfx/graphviz )"

RDEPEND=""


src_prepare() {
	if ! use examples; then
		sed -i -e "/examples/d" ${S}/Makefile
	fi
}

src_install() {
	if use htmldoc; then
		emake DESTDIR="${D}" PREFIX="/usr" install
	else
		emake DESTDIR="${D}" PREFIX="/usr" DOXYGEN='' install
	fi
}
