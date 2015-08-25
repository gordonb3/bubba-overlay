# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils git-r3 systemd

EGIT_REPO_URI="git://github.com/domoticz/domoticz.git"

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
	# create build directory and create copy of .git folder in it
	ln -s ${S} ${WORKDIR}/${PF}_build

	# disable static boost:
	sed \
		-e "s:\${USE_STATIC_BOOST}:OFF:" \
		-i CMakeLists.txt
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use staticboost USE_STATIC_BOOST)
	)
#		-DCMAKE_BUILD_TYPE=Release

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
