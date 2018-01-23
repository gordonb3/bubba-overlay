# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils gnome2 flag-o-matic cmake-utils toolchain-funcs

#versions to use for libsigc++ and libeutils
SIG_PV=2.4.1
UTL_PV=0.7.39

MY_PV=${PV/_*/}
DESCRIPTION="Bubba network manager allows the web frontend to control various network settings"
HOMEPAGE="http://www.excito.com/"
SRC_URI="
	http://b3.update.excito.org/pool/main/b/${PN}/${PN}_${MY_PV}.tar.gz
	https://download.gnome.org/sources/libsigc++/2.4/libsigc++-${SIG_PV}.tar.xz
	http://b3.update.excito.org/pool/main/libe/libeutils/libeutils_${UTL_PV}.tar.gz
"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+wifi systemd"

DEPEND="
	dev-libs/glib
	dev-libs/libnl
	dev-libs/popt
	dev-tcltk/expect
	dev-util/cppunit
	dev-util/cmake
	systemd? ( net-misc/networkmanager[dhcpcd,-dhclient] )
	sys-devel/libtool
	sys-devel/m4
"

RDEPEND="${DEPEND}
	net-misc/dhcpcd
	wifi? ( net-misc/bridge-utils
		net-wireless/hostapd
		net-wireless/iw
		net-wireless/wireless-tools )
	systemd? ( sys-apps/systemd )
"

S=${WORKDIR}/${PN}-${MY_PV}
CMAKE_IN_SOURCE_BUILD=yes

pkg_setup() {
	if [ ! -e ${ROOT}/usr/lib/libexpect.so ]; then
		rm -f ${ROOT}/usr/lib/libexpect.so
		ln -s $(ls ${ROOT}/usr/lib/expect*/libexpect*.so) ${ROOT}/usr/lib/libexpect.so
	fi
}


sigc_prepare() {
	cd ../libsigc++-${SIG_PV}
	sed -i 's|^\(SUBDIRS =.*\)examples\(.*\)$|\1\2|' \
		Makefile.am Makefile.in || die "sed examples failed"

	# don't waste time building tests unless USE=test
	sed -i 's|^\(SUBDIRS =.*\)tests\(.*\)$|\1\2|' \
		Makefile.am Makefile.in || die "sed tests failed"

	gnome2_src_prepare
	cd - &>/dev/null
}


sigc_configure() {
	einfo "configuring libsigc++"
	cd ../libsigc++-${SIG_PV}
	filter-flags -fno-exceptions #84263

	ECONF_SOURCE="${WORKDIR}/libsigc++-${SIG_PV}" gnome2_src_configure --enable-static

	cd - &>/dev/null
}


sigc_compile() {
	einfo "compiling libsigc++"
	cd ../libsigc++-${SIG_PV}
	default
	cd - &>/dev/null
}


utl_prepare() {
	S=${WORKDIR}/libeutils
	pushd "${S}" > /dev/null
	epatch ${FILESDIR}/libeutils-${UTL_PV}.patch
	ln -s ${WORKDIR}/libsigc++-${SIG_PV} include
	sed -e "s/\$.SIGC++_CFLAGS./-I..\/include/" -i libeutils/CMakeLists.txt
	sed -e "/SIGC++/d" -e "/TUT/d" -e "s/ on /@@/" -e "s/ off / on /" -e "s/@@/ off /" -i CMakeLists.txt
	mkdir ${WORKDIR}/libsigc++-${SIG_PV}/sigc++/.libs ${WORKDIR}/libeutils/lib
	ln -s ${WORKDIR}/libsigc++-${SIG_PV}/sigc++/.libs ${WORKDIR}/libeutils/lib/sigc++
	popd > /dev/null
	cmake-utils_src_prepare
	S=${WORKDIR}/${PN}-${MY_PV}
}


utl_configure() {
	einfo "configuring eutils"
	S=${WORKDIR}/libeutils
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX=/usr
		-DCMAKE_VERBOSE_MAKEFILE=OFF
		-DBUILD_STATIC_LIBRARIES=ON
	)
	cmake-utils_src_configure
	S=${WORKDIR}/${PN}-${MY_PV}
}


utl_compile() {
	einfo "compiling eutils"
	S=${WORKDIR}/libeutils
	cmake-utils_src_compile
	S=${WORKDIR}/${PN}-${MY_PV}
}


src_prepare() {
	# prepare include libraries
	sigc_prepare
	utl_prepare

	epatch ${FILESDIR}/gentoo.patch
	epatch ${FILESDIR}/netlink3.patch
	epatch ${FILESDIR}/dialup-support.patch
	epatch ${FILESDIR}/fqdn-compliancy.patch
	if use systemd; then
		epatch ${FILESDIR}/systemd-networkmanager.patch
		epatch ${FILESDIR}/systemd-cpp5.patch
	else
		epatch ${FILESDIR}/netifrc.patch
		epatch ${FILESDIR}/netifrc-sysfs.patch
	fi

	# static linking of libsigc++ and libeutils
	sed \
		-e "s/libeutils/glib-2.0/g" \
		-e "s/Wall/Wall -I\$(CURDIR)\/include/" \
		-e "s/LDFLAGS =/LDFLAGS = libeutils.a libsigc-2.0.a -lpopt -lpthread -lexpect/" \
		-e "s/\-o \$@ \$\^/\-o \$@/g" \
		-e "s/\$(LDFLAGS)/\$\^ \$(LDFLAGS)/g" \
		-i Makefile || die
}


src_configure() {
	sigc_configure
	utl_configure
}


src_compile() {
	sigc_compile
	utl_compile

	einfo "compiling main application"

	# add include folder and static libs
	ln -s ${WORKDIR}/libsigc++-${SIG_PV} ${S}/include
	ln -s ${WORKDIR}/libeutils/libeutils ${S}/include/
	cp -al ${S}/include/libeutils/json/include/json/* ${S}/include/libeutils/json/
	ln -s ${WORKDIR}/libsigc++-${SIG_PV}/sigc++/.libs/libsigc-2.0.a ${S}/
	ln -s ${WORKDIR}/libeutils/libeutils/libeutils.a ${S}/

	emake CXX=$(tc-getCXX) DESTDIR="${ED}"
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

	dodoc ${FILESDIR}/Changelog debian/copyright
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
			newexe ${FILESDIR}/lan-bridge.nm-dispatcher 30-lan-bridge
			fperms 0755 /etc/NetworkManager/dispatcher.d/30-lan-bridge
		fi
	fi

	insinto /etc/dnsmasq.d
	newins ${FILESDIR}/dnsmasq.conf bubba.conf

	if use systemd; then
		exeinto /etc/NetworkManager/dispatcher.d/
		newexe ${FILESDIR}/bubba-fqdn.nm-dispatcher 50-bubba-fqdn
		fperms 0755 /etc/NetworkManager/dispatcher.d/50-bubba-fqdn
	else
		insinto /lib/dhcpcd/dhcpcd-hooks
		doins ${FILESDIR}/bubba-fqdn.hook
	fi
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
