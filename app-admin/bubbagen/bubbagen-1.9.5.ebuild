# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="The Bubba main package"
HOMEPAGE="https://github.com/gordonb3/bubbagen"
KEYWORDS="~arm ~ppc"
VMAJOR=${PV:0:3}
SRC_URI="https://github.com/gordonb3/bubbagen/archive/${VMAJOR}.tar.gz -> ${P}.tgz"
LICENSE="GPL-3+"
SLOT="0/${VMAJOR}.5"
RESTRICT="mirror"
IUSE="systemd"

REQUIRED_USE="systemd"

# Conflicts/replaces Sakaki's b3-init-scripts
DEPEND="
	!sys-apps/b3-init-scripts
	>=virtual/udev-215
	>=sys-apps/ethtool-3.12.1
	!virtual/bubba:0/0
"

RDEPEND="${DEPEND}
	app-admin/bubba-frontend[systemd]
	app-admin/bubba-backend[systemd]
	app-admin/bubba-manual
	sys-power/bubba-buttond[systemd]
	sys-apps/systemd
"

#src_unpack() {
#	default
#
#	mv ${WORKDIR}/${PN}* ${S}
#}

src_prepare() {
	# Git does not support empty folders
	# clean up the bogus content here.
	find ${S} -name ~nofiles~ -exec rm {} \;
	cp -a ${S}/systemd/* ${S}/
}


src_install() {
        dodir "/etc/bubba"
	echo ${PV} > ${ED}/etc/bubba/bubba.version

	echo "Create bubba-default-config archive"
	tar -czf bubba-default-config.tgz etc
	insinto /var/lib/bubba
	doins bubba-default-config.tgz

	exeinto /opt/bubba/sbin
	doexe sbin/*
	chmod 700 ${ED}/opt/bubba/sbin/*

	if use arm; then
		echo "Add udev rules"
		insinto /lib/udev/rules.d
		newins	${FILESDIR}/marvell-fix-tso.udev 50-marvell-fix-tso.rules
		newins	${FILESDIR}/net-name-use-custom.udev 70-net-name-use-custom.rules
	fi
}

