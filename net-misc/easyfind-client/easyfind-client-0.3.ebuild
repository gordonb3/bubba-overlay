# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils systemd

EF_SRC="easyfind-client"
EF_COMMIT="63fb971917070275af152d499fe2880207d47114"
CA_SRC="excito-release"
CA_COMMIT="1c12d4e974b54619bde2997f53fc5b77e08d61a8"

SRC_URI="https://github.com/Excito/${EF_SRC}/archive/${EF_COMMIT}.zip -> ${PN}-${PV}.zip
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
	unpack ${PN}-${PV}.zip
	mv ${WORKDIR}/${EF_SRC}-${EF_COMMIT} ${S}
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
		newinitd ${FILESDIR}/easyfind-client.initd ${PN}
	fi
	if use dhcp; then
		insinto /lib/dhcpcd/dhcpcd-hooks
		doins ${FILESDIR}/easyfind-client.hook
	fi
	dodoc ${S}/debian/changelog  ${S}/debian/copyright
}
