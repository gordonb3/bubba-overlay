# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

MY_PV=${PV/_*/}
DESCRIPTION="Bubba network manager allows the web frontend to control various network settings"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/b/${PN}/${PN}_${MY_PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+wifi systemd"

DEPEND="
	dev-libs/glib
	dev-libs/libeutils
	dev-libs/libnl
	dev-libs/libsigc++
	dev-libs/popt
	systemd? ( net-misc/networkmanager[-dhclient,dhcpcd] )
"

RDEPEND="${DEPEND}
	net-misc/dhcpcd
	wifi? ( net-misc/bridge-utils
		net-wireless/hostapd
		net-wireless/iw
		net-wireless/wireless-tools )
"

S=${WORKDIR}/${PN}-${MY_PV}

src_prepare() {
	epatch ${FILESDIR}/${PN}-${MY_PV}-paths.patch
	epatch ${FILESDIR}/${PN}-${MY_PV}-nl3.patch
	epatch ${FILESDIR}/${PN}-${MY_PV}-ifcommands.patch
        epatch ${FILESDIR}/${PN}-${MY_PV}-ifpolicies.patch
        epatch ${FILESDIR}/${PN}-${MY_PV}-fqdn.patch
	if use systemd; then
		epatch ${FILESDIR}/${PN}-${MY_PV}-systemd.patch
	else
		epatch ${FILESDIR}/${PN}-${MY_PV}-netconf.patch
	fi
}

src_compile() {
        emake DESTDIR="${ED}"
}

src_install() {
	exeinto /opt/bubba/sbin
	doexe bubba-networkmanager

	exeinto /opt/bubba/bin/
	doexe bubba-networkmanager-cli

	insinto /etc/bubba
	newins examplecfg/nmconfig networkmanager.conf

	insinto /var/lib/bubba
	doins tz-lc.txt

	dodoc debian/copyright ${FILESDIR}/Changelog
	newdoc debian/changelog changelog.debian

        # Check whether we have wifi support
	if use wifi; then
	        if $(iwconfig 2>/dev/null| grep -q 802\.11); then
        	        ip link show wlan0 &>/dev/null || {
                	        ewarn "Your wifi adapter is incorrectly named"
                        	ewarn "Bubba-networkmanager will not handle your"
	                        ewarn "wifi settings unless you rename it to wlan0"
        	        }
		fi

		if use systemd; then
			exeinto /etc/NetworkManager/dispatcher.d/
			newexe ${FILESDIR}/lan-bridge-dispatcher.sh 30-lan-bridge
			fperms 0755 /etc/NetworkManager/dispatcher.d/30-lan-bridge
		fi
        fi

	insinto /etc/dnsmasq.d
	newins ${FILESDIR}/dnsmasq.conf bubba.conf

	insinto /lib/dhcpcd/dhcpcd-hooks
	doins ${FILESDIR}/bubba-fqdn.hook
}


pkg_postinst() {
	if use systemd; then
		systemctl is-enabled NetworkManager &>/dev/null || systemctl enable NetworkManager
		systemctl is-active NetworkManager &>/dev/null || systemctl start NetworkManager
		# Networkmanager conflicts with dhcpcd service
		systemctl is-enabled dhcpcd &>/dev/null && systemctl disable dhcpcd
		systemctl is-active dhcpcd &>/dev/null && systemctl stop dhcpcd
		systemctl is-enabled dhcpcd@ &>/dev/null && systemctl disable dhcpcd@
		systemctl is-active dhcpcd@ &>/dev/null && systemctl stop dhcpcd@
		if use wifi; then
			systemctl is-enabled NetworkManager-dispatcher &>/dev/null || systemctl enable NetworkManager-dispatcher
			systemctl is-active NetworkManager-dispatcher &>/dev/null || systemctl start NetworkManager-dispatcher
		fi
	fi
}
