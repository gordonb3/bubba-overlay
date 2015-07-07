# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/b/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

DEPEND="
	dev-libs/glib
	dev-libs/libeutils
	dev-libs/libsigc++
	sys-block/parted
	sys-fs/lvm2
"

RDEPEND="${DEPEND}
	sys-fs/mdadm
"

S=${WORKDIR}/${PN}


src_prepare() {
	sed -i "s/ \(\/lib\/libparted.so.2\)/ \/usr\1/" Makefile

	sed -i "s/\/sbin\/udevadm/\/bin\/udevadm/" Disks.cpp
}

src_install() {
	exeinto /usr/sbin
	doexe diskmanager

	dodoc debian/changelog debian/copyright
}


