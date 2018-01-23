# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils gnome2 flag-o-matic cmake-utils toolchain-funcs


SIG_PV=2.4.1
UTL_PV=0.7.39

DESCRIPTION="Bubba disk manager handles disk functions for the Bubba web frontend"
HOMEPAGE="http://www.excito.com/"
SRC_URI="
	http://b3.update.excito.org/pool/main/b/${PN}/${PN}_${PV}.tar.gz
	https://download.gnome.org/sources/libsigc++/2.4/libsigc++-${SIG_PV}.tar.xz
	http://b3.update.excito.org/pool/main/libe/libeutils/libeutils_${UTL_PV}.tar.gz
"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""

DEPEND="
	dev-libs/glib
	dev-libs/popt
	dev-tcltk/expect
	dev-util/cppunit
	dev-util/cmake
	sys-block/parted
	sys-devel/libtool
	sys-devel/m4
	sys-fs/lvm2
"

RDEPEND="${DEPEND}
	sys-fs/mdadm
"

S=${WORKDIR}/${PN}


CMAKE_IN_SOURCE_BUILD=yes

pkg_setup() {
	if [ ! -e ${ROOT}/usr/lib/libexpect.so ]; then
		rm -f ${ROOT}/usr/lib/libexpect.so
		ln -s $(ls ${ROOT}/usr/lib/expect*/libexpect*.so) ${ROOT}/usr/lib/libexpect.so
	fi
}


sigc_prepare() {
	cd ../libsigc++-${SIG_PV}
	sed -i 's|^\(SUBDIRS =.*\)examples\(.*\)$|\1\2|' \
		Makefile.am Makefile.in || die "sed examples failed"

	# don't waste time building tests unless USE=test
	sed -i 's|^\(SUBDIRS =.*\)tests\(.*\)$|\1\2|' \
		Makefile.am Makefile.in || die "sed tests failed"

	gnome2_src_prepare
	cd - &>/dev/null
}


sigc_configure() {
	einfo "configuring libsigc++"
	cd ../libsigc++-${SIG_PV}
	filter-flags -fno-exceptions #84263

	ECONF_SOURCE="${WORKDIR}/libsigc++-${SIG_PV}" gnome2_src_configure --enable-static

	cd - &>/dev/null
}


sigc_compile() {
	einfo "compiling libsigc++"
	cd ../libsigc++-${SIG_PV}
	default
	cd - &>/dev/null
}


utl_prepare() {
	S=${WORKDIR}/libeutils
	pushd "${S}" > /dev/null
	epatch ${FILESDIR}/libeutils-${UTL_PV}.patch
	ln -s ${WORKDIR}/libsigc++-${SIG_PV} include
	sed -e "s/\$.SIGC++_CFLAGS./-I..\/include/" -i libeutils/CMakeLists.txt
	sed -e "/SIGC++/d" -e "/TUT/d" -e "s/ on /@@/" -e "s/ off / on /" -e "s/@@/ off /" -i CMakeLists.txt
	mkdir ${WORKDIR}/libsigc++-${SIG_PV}/sigc++/.libs ${WORKDIR}/libeutils/lib
	ln -s ${WORKDIR}/libsigc++-${SIG_PV}/sigc++/.libs ${WORKDIR}/libeutils/lib/sigc++
	popd > /dev/null
	cmake-utils_src_prepare
	S=${WORKDIR}/${PN}
}

utl_configure() {
	einfo "configuring eutils"
	S=${WORKDIR}/libeutils
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX=/usr
		-DCMAKE_VERBOSE_MAKEFILE=OFF
		-DBUILD_STATIC_LIBRARIES=ON
	)
	cmake-utils_src_configure
	S=${WORKDIR}/${PN}
}

utl_compile() {
	einfo "compiling eutils"
	S=${WORKDIR}/libeutils
	cmake-utils_src_compile
	S=${WORKDIR}/${PN}
}




src_prepare() {
	# prepare include libraries
	sigc_prepare
	utl_prepare

	sed -i "s/ \(\/lib\/libparted.so.2\)/ \/usr\1/" Makefile

	sed -i "s/\/sbin\/udevadm/\/bin\/udevadm/" Disks.cpp

	# static linking of libsigc++ and libeutils
	sed \
		-e "s/cflags libeutils)/cflags glib-2.0) -I\$(CURDIR)\/include/" \
		-e "s/\/usr\/lib\/libparted.so.2/libeutils.a libsigc-2.0.a -lpthread -lexpect/" \
		-e "s/sigc++-2.0 libeutils/glib-2.0/" \
		-i Makefile
}


src_configure() {
	sigc_configure
	utl_configure
}


src_compile() {
	sigc_compile
	utl_compile

	einfo "compiling main application"

	# add include folder and static libs
	ln -s ${WORKDIR}/libsigc++-${SIG_PV} ${S}/include
	ln -s ${WORKDIR}/libeutils/libeutils ${S}/include/
	cp -al ${S}/include/libeutils/json/include/json/* ${S}/include/libeutils/json/
	ln -s ${WORKDIR}/libsigc++-${SIG_PV}/sigc++/.libs/libsigc-2.0.a ${S}/
	ln -s ${WORKDIR}/libeutils/libeutils/libeutils.a ${S}/

	emake CXX=$(tc-getCXX)
}


src_install() {
	exeinto /opt/bubba/sbin
	doexe diskmanager

	dodoc ${FILESDIR}/Changelog debian/copyright
	newdoc debian/changelog changelog.debian
}

