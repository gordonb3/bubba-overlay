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
IUSE="+dhcp +remote-router"

DEPEND="dev-embedded/u-boot-tools"

RDEPEND="${DEPEND}
	remote-router? ( dev-python/twisted-web
		dev-python/netifaces
		dev-python/configobj
	)
	dev-perl/JSON
	dev-perl/libwww-perl
"

S=${WORKDIR}/bubba-backend


src_prepare() {
	epatch ${FILESDIR}/${PF}.patch
}


src_install() {
	insinto /etc/bubba
	doins bubbakey

	if use dhcp; then
		insinto /lib/dhcpcd/dhcpcd-hooks
		doins bubba-easyfind.hook
	fi

	if use remote-router; then
		insinto /opt/bubba/bin
		doins bubba-easyfind.tac
		doinitd bubba-easyfind
	fi

	exeinto /opt/bubba/bin
	doexe print-u-boot-env web-admin/bin/easyfind.pl

	dodoc "debian/copyright"
	dodir /usr/share/doc/${PF}/sample
	mv bubba-easyfind bubba-easyfind.initd
	cp -a bubba-easyfind.hook bubba-easyfind.tac bubba-easyfind.initd ${ED}/usr/share/doc/${PF}/sample/
}


pkg_postinst() {
	elog "To manually enable easyfind, run:"
	elog ""
	elog "\t/opt/bubba/bin/easyfind.pl setname <your name>"
	elog ""
	elog "If you did not disable the dhcp USE flag, a DHCP hook"
	elog "script is provided to automatically update your IP on"
	elog "the easyfind server. If however you have your B3 behind"
	elog "another router, then you should enable the bubba-easyfind"
	elog "service to track changes in your public IP address."
	elog ""
	elog ""
}
