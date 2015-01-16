# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: www-apps/domoticz-9999.ebuild,v 1.4 2014/11/14 18:31:12 by frostwork Exp $

EAPI="5"

inherit cmake-utils eutils subversion systemd

ESVN_REPO_URI="svn://svn.code.sf.net/p/domoticz/code/trunk"

DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="-staticboost systemd"

RDEPEND="net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost
	sys-libs/zlib"

DEPEND="${RDEPEND}
	dev-util/cmake"

src_prepare() {
# create svnrevision file with subversion eclass internals:
	echo "#define SVNVERSION ${ESVN_WC_REVISION}" > ${S}/svnversion.h

# ugly hack to disable generating the original svnrevision:
	sed -i -e "s:ADD_CUSTOM_COMMAND(TARGET:#:" -i CMakeLists.txt
	sed -i -e "s:-DSOURCE_DIR:#:" -i CMakeLists.txt
	sed -i -e "s:-P:#:" -i CMakeLists.txt

# install binary to /usr/bin/
#	sed -i -e "s:install(TARGETS domoticz DESTINATION /opt/domoticz):install(TARGETS domoticz DESTINATION /usr/bin):" -i CMakeLists.txt

# install svnversion.h to /usr/share/domoticz/
	sed -i -e "s:filename=szStartupFolder+\"svnversion.h\":filename=\"/opt/domoticz/svnversion.h\":" -i main/domoticz.cpp

#	sed -i -e "s:/opt/domoticz:/usr/share/domoticz:" -i CMakeLists.txt
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use staticboost USE_STATIC_BOOST)
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	if use systemd ; then
		systemd_newunit "${FILESDIR}"/${PN}.service "${PN}.service"
		systemd_install_serviced "${FILESDIR}"/${PN}.service.conf
	else
		newinitd "${FILESDIR}"/${PN}.init.d ${PN}
		newconfd "${FILESDIR}"/${PN}.conf.d ${PN}
	fi
}
