# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils

DESCRIPTION="Excito library utils"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://b3.update.excito.org/pool/main/libe/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""

DEPEND="
	dev-libs/glib
	<dev-libs/libsigc++-2.6:2
	dev-libs/popt
	dev-tcltk/expect
	dev-util/cppunit
	dev-util/cmake
	sys-devel/libtool
"

RDEPEND="${DEPEND}"

S=${WORKDIR}/${PN}


pkg_setup() {
	if [ ! -e ${ROOT}/usr/lib/libexpect.so ]; then
		rm -f ${ROOT}/usr/lib/libexpect.so
		ln -s $(ls ${ROOT}/usr/lib/expect*/libexpect*.so) ${ROOT}/usr/lib/libexpect.so
	fi
}

src_prepare() {
	epatch ${FILESDIR}/${P}.patch
}


src_configure() {
	cmake-utils_src_configure -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=OFF -DBUILD_STATIC_LIBRARIES=OFF
}


src_install() {
	cmake-utils_src_install
	dodoc debian/changelog debian/copyright
}
