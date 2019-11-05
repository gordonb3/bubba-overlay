# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils systemd gnome2 flag-o-matic cmake-utils toolchain-funcs


SIG_PV=2.4.1
UTL_PV=0.7.39

DESCRIPTION="Excito library utils"
HOMEPAGE="http://www.excito.com/"
SRC_URI="
	http://b3.update.excito.org/pool/main/f/${PN}/${PN}_${PV}.tar.gz
	https://download.gnome.org/sources/libsigc++/2.4/libsigc++-${SIG_PV}.tar.xz
	http://b3.update.excito.org/pool/main/libe/libeutils/libeutils_${UTL_PV}.tar.gz
"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+apache2 +upload +libtorrent systemd"

DEPEND="
	dev-libs/popt
	dev-libs/boost
	dev-tcltk/expect
	dev-util/cppunit
	dev-util/cmake
	libtorrent? (
	    <net-libs/libtorrent-rasterbar-1.1
	    <dev-libs/boost-1.70
	)
	sys-devel/libtool
	sys-devel/m4
"

RDEPEND="${DEPEND}
	apache2? ( www-servers/apache[apache2_modules_cgi] )
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

	epatch ${FILESDIR}/libtorrent-rasterbar.patch
	epatch ${FILESDIR}/gcc5.patch

	if ! use libtorrent; then 
		sed \
			-e "s/TorrentDownloader.cpp//" \
			-e "s/DirWatcher.cpp//" \
			-e "s/libtorrent-rasterbar //g" \
			-e "s/^LD_LIBTORRENT.*$/LD_LIBTORRENT=\\\/" \
			-i Makefile

		sed \
			-e "/TorrentDownloader.h/c\ " \
			-e "/TorrentDownloadManager/c\ " \
			-i src/filetransferdaemon.cpp
	fi

	if ! ( use apache2 && use upload ); then
		if use upload; then
			ewarn "Refusing to build upload.cgi"
			ewarn "Uploads are only supported with apache web server"
		fi
		sed \
			-e "s/ \$.UPLOAD_CGI.//g" \
			-i Makefile
	fi

	# static linking of libsigc++ and libeutils
        sed \
                -e "s/cflags libeutils/cflags/" \
                -e "s/sigc++-2.0 libcurl)/libcurl glib-2.0) \-I\$(CURDIR)\/include/" \
                -e "s/LDFLAGS_EXTRA =/LDFLAGS_EXTRA = libeutils.a libsigc-2.0.a -lpthread/" \
                -e "s/libs libeutils sigc++-2.0/libs glib-2.0/" \
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

	emake CXX=$(tc-getCXX) VERSION="${PV}" CFGPATH="/etc/bubba/ftdconfig.ini"
}


src_install() {
	docompress -x /usr/share/doc/${PF}

	exeinto /opt/bubba/bin
	doexe ftdclient

	insinto /opt/bubba/web-admin/ftd
	doins php/ipc.php

	dodoc ${FILESDIR}/Changelog debian/copyright
	newdoc ftdconfig.ini ftdconfig.default
	newdoc debian/changelog changelog.debian

	if use systemd; then
		systemd_dounit "${FILESDIR}"/${PN}.service
	else
		newinitd "${FILESDIR}"/${PN}.initd ${PN}
	fi

	exeopts -m700
	exeinto /opt/bubba/sbin
	doexe ftd

	use upload && use apache2 && {
		exeinto /opt/bubba/web-admin/cgi-bin
		doexe upload.cgi
		fowners apache.root /opt/bubba/web-admin/cgi-bin/upload.cgi
	}
}


pkg_postinst() {
	if [ ! -r /etc/bubba/ftdconfig.ini ];then
		cp /usr/share/doc/${PF}/ftdconfig.default /etc/bubba/ftdconfig.ini
	fi
}

