# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Free software library that interfaces with selected Z-Wave PC controllers"
HOMEPAGE="http://www.openzwave.net/"

SRC_URI="http://old.openzwave.com/downloads/${P}.tar.gz"
RESTRICT="mirror"
LICENSE="GPL-3 Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~x86"
IUSE="-examples -htmldoc"

DEPEND="htmldoc? ( app-doc/doxygen  media-gfx/graphviz )"

RDEPEND=""

src_prepare() {
	if ! use examples; then
		sed -e "/examples/d" -i ${S}/Makefile
	fi

	if ! use htmldoc; then
		sed -e "/^DOT /d" \
		    -e "/^DOXYGEN /d" \
		    -i ${S}/cpp/build/support.mk
	fi

	# Portage does not set CROSS_COMPILE env var - use CHOST instead
	sed -e "s/CROSS_COMPILE)/CHOST)-/g" \
	    -i ${S}/cpp/build/support.mk
}

src_compile() {
	emake DESTDIR="${D}" PREFIX="/usr" sysconfdir="/var/lib/openzwave"
}

src_install() {
	emake DESTDIR="${D}" PREFIX="/usr" sysconfdir="/var/lib/openzwave" install

	# fix doc location
	mv ${D}/usr/share/doc/${P} ${D}/usr/share/doc/${PF}
}

