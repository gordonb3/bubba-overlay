# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils subversion systemd

ESVN_REPO_URI="svn://svn.code.sf.net/p/domoticz/code/trunk"

DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
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

	# disable generating the original svnrevision:
	sed \
		-e "s:ADD_CUSTOM_COMMAND(TARGET:#:" \
		-e "s:-DSOURCE_DIR:#:" \
		-e "s:-P:#:" \
		-e "s:\${USE_STATIC_BOOST}:OFF:" \
		-i CMakeLists.txt

	# install svnversion.h to /usr/share/domoticz/
	sed \
		-e "s:filename=szStartupFolder+\"svnversion.h\":filename=\"/opt/domoticz/svnversion.h\":" \
		-i main/domoticz.cpp

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
