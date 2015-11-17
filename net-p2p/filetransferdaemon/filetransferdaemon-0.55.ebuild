# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Excito library utils"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/f/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""

DEPEND="
	dev-libs/libeutils
	dev-libs/libsigc++
	dev-libs/popt
	dev-libs/boost
	net-libs/rb_libtorrent
"

RDEPEND="${DEPEND}
	www-servers/apache[cgi]
"

S=${WORKDIR}/${PN}


src_prepare() {
	epatch ${FILESDIR}/${P}.patch
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

	newinitd "${FILESDIR}"/${PN}.initd ${PN}

	exeopts -m700
	exeinto /opt/bubba/sbin
	doexe ftd

	exeinto /opt/bubba/web-admin/cgi-bin
	doexe upload.cgi
	fowners apache.root /opt/bubba/web-admin/cgi-bin/upload.cgi
}

