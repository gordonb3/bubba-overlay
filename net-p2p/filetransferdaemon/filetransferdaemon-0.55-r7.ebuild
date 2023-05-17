# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit systemd gnome2 flag-o-matic cmake toolchain-funcs


DESCRIPTION="Excito File Transfer Daemon"
HOMEPAGE="http://www.excito.com/"
SRC_URI="https://github.com/gordonb3/${PN}/archive/${PVR}.tar.gz -> ${PF}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+apache2 +upload libtorrent systemd"

PATCHES=(
	"${FILESDIR}/libeutils-0.7.39.patch"
)

DEPEND="
	dev-libs/popt
	>=dev-libs/boost-1.77
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

CMAKE_IN_SOURCE_BUILD=yes


src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-* ${S}
}

src_prepare() {
	eapply_user

	if use libtorrent; then 
		eapply ${FILESDIR}/libtorrent-rasterbar.patch
		eapply ${FILESDIR}/gcc5.patch
	fi

	if ! ( use apache2 && use upload ); then
		if use upload; then
			ewarn "Refusing to build upload.cgi"
			ewarn "Uploads are only supported with apache web server"
		fi
		sed -e "s/ \$\(UPLOAD_CGI\)//" -e "/www-data/d" -i bubba-ftd/Makefile
	else
		sed -e "s/\-\-owner=www-data//" -i bubba-ftd/Makefile
	fi

	cmake_src_prepare
}


src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DWITH_LIBTORRENT=$(usex libtorrent)
	)

	cmake_src_configure
}


src_install() {
	docompress -x /usr/share/doc/${PF}

	exeinto /opt/bubba/bin
	doexe _deploy/usr/bin/ftdclient

	insinto /opt/bubba/web-admin/ftd
	doins _deploy/usr/share/ftd/ipc.php

	dodoc ${FILESDIR}/Changelog bubba-ftd/debian/copyright _deploy/usr/share/ftd/ftdconfig.default
	newdoc bubba-ftd/debian/changelog changelog.debian

	if use systemd; then
		systemd_dounit "${FILESDIR}"/${PN}.service
	else
		newinitd "${FILESDIR}"/${PN}.initd ${PN}
	fi

	exeopts -m700
	exeinto /opt/bubba/sbin
	doexe _deploy/usr/sbin/ftd

	use upload && use apache2 && {
		exeinto /opt/bubba/web-admin/cgi-bin
		doexe _deploy/usr/lib/cgi-bin/upload.cgi
		fowners apache:root /opt/bubba/web-admin/cgi-bin/upload.cgi
	}
}


pkg_postinst() {
	if [ ! -r /etc/bubba/ftdconfig.ini ];then
		cp /usr/share/doc/${PF}/ftdconfig.default /etc/bubba/ftdconfig.ini
	fi
}

