# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils systemd

DESCRIPTION="Excito library utils"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/f/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+apache2 +upload +libtorrent systemd"

DEPEND="
	dev-libs/libeutils
	<dev-libs/libsigc++-2.6:2
	dev-libs/popt
	dev-libs/boost
	libtorrent? ( net-libs/libtorrent-rasterbar )
"

RDEPEND="${DEPEND}
	apache2? ( www-servers/apache[apache2_modules_cgi] )
"

S=${WORKDIR}/${PN}


src_prepare() {
	epatch ${FILESDIR}/${PF}.patch

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
}

src_compile() {
	make VERSION="${PV}" CFGPATH="/etc/bubba/ftdconfig.ini"
}

src_install() {
	docompress -x /usr/share/doc/${PF}

	exeinto /opt/bubba/bin
	doexe ftdclient

	insinto /opt/bubba/web-admin/ftd
	doins php/ipc.php

	dodoc debian/changelog debian/copyright
	newdoc ftdconfig.ini ftdconfig.default

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
