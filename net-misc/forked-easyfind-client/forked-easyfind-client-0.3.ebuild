# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils systemd

CA_SRC="excito-release"
CA_COMMIT="1c12d4e"

SRC_URI="
	https://github.com/gordonb3/${PN}/archive/debian/${PV}.tar.gz -> ${PF}.tgz
	https://raw.githubusercontent.com/Excito/${CA_SRC}/${CA_COMMIT}/excito-ca.crt
"

RESTRICT="mirror"
DESCRIPTION="Easyfind client"
HOMEPAGE="http://www.excito.com/"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+dhcp +remote-router"


RDEPEND="net-misc/curl
	dev-libs/json-c
	!<net-misc/bubba-easyfind-3
"

DEPEND="${RDEPEND}"


src_unpack() {
	unpack ${PF}.tgz
	mv ${WORKDIR}/${PN}* ${S}
}

src_compile() {
	make EXTRAFLAGS="-DEXCITO_CA=\\\"/etc/ssl/certs/Excito_CA.pem\\\" -DSTATE_DIR=\\\"/etc/bubba\\\" -DPID_FILE=\\\"/run/easyfind.pid\\\""
}

src_install() {
	insinto /etc/bubba
	insinto /etc/ssl/certs
	newins ${DISTDIR}/excito-ca.crt Excito_CA.pem
	exeinto /opt/bubba/bin
	doexe ${S}/ef
	dosym /opt/bubba/bin/ef /opt/bubba/bin/easyfind.pl
	if use remote-router; then
		exeinto /opt/bubba/sbin
		dosym /opt/bubba/bin/ef /opt/bubba/sbin/efd
		newinitd ${FILESDIR}/easyfind-client.initd bubba-easyfind
	fi
	if use dhcp; then
		insinto /lib/dhcpcd/dhcpcd-hooks
		doins ${FILESDIR}/easyfind-client.hook
	fi
	dodoc ${S}/debian/changelog  ${S}/debian/copyright
}

pkg_postinst() {
	elog "To manually enable easyfind, run:"
	elog ""
	elog "\t/opt/bubba/bin/ef <your name>"
	elog ""
	elog "If you did not disable the dhcp USE flag, a DHCP hook"
	elog "script is provided to automatically update your IP on"
	elog "the easyfind server. If however you have your B3 behind"
	elog "another router, then you should enable the bubba-easyfind"
	elog "service to track changes in your public IP address."
	elog ""
	elog ""
}
