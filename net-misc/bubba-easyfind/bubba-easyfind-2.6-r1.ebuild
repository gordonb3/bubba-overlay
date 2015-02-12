# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Excito B3 easyfind service"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/b/bubba-backend/bubba-backend_${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

RDEPEND="dev-embedded/u-boot-tools"

DEPEND="${RDEPEND}
	dev-python/twisted-web
	dev-perl/JSON
	dev-perl/libwww-perl
	dev-python/netifaces
	dev-python/configobj"

S=${WORKDIR}/bubba-backend


src_prepare() {
	patch -p1 < ${FILESDIR}/${PN}.patch
	chmod 755 "${S}/bubba-easyfind" \
		"${S}/print-u-boot-env" \
		"${S}/web-admin/bin/easyfind.pl"
	chmod 644 "${S}/bubba-easyfind.tac"
	chmod 444 "${S}/bubba-easyfind.hook"
}


src_install() {
	dodir /lib/dhcpcd/dhcpcd-hooks
	cp -a "${S}/bubba-easyfind.hook"   ${ED}/lib/dhcpcd/dhcpcd-hooks/80-bubba-easyfind

	dodir /opt/bubba/scripts
	cp -a "${S}/bubba-easyfind.tac"   ${ED}/opt/bubba/scripts
	cp -a "${S}/print-u-boot-env"   ${ED}/opt/bubba/scripts
	cp -a "${S}/web-admin/bin/easyfind.pl"   ${ED}/opt/bubba/scripts

	dodir /etc/bubba
	cp -a "${S}/bubbakey"   ${ED}/etc/bubba

	dodir /etc/init.d
	cp -a "${S}/bubba-easyfind"   ${ED}/etc/init.d

	dodoc "${S}/debian/copyright"


	elog "To enable easyfind, run:"
	elog ""
	elog "\t/opt/bubba/scripts/easyfind.pl setname <your name>"
	elog ""
	elog "A DHCP hook script is provided to automatically update"
	elog "your IP on the easyfind server. If however you have"
	elog "your B3 behind another router, then you should enable"
	elog "the bubba-easyfind service to track changes in your"
	elog "public IP address."
	elog ""
}
