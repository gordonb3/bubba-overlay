# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils git-r3 systemd

EGIT_REPO_URI="git://github.com/domoticz/domoticz.git"

DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="systemd telldus openzwave"

RDEPEND="net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost
	sys-libs/zlib
	telldus? ( app-misc/telldus-core )
	openzwave? ( dev-libs/openzwave )
"

DEPEND="${RDEPEND}
	dev-util/cmake"

src_prepare() {
	# link build directory
	ln -s ${S} ${WORKDIR}/${PF}_build

	# Hard disable static boost:
	sed \
		-e "s:\${USE_STATIC_BOOST}:OFF:" \
		-i CMakeLists.txt
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DCMAKE_INSTALL_PREFIX="/opt/domoticz"
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
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

	insinto /var/lib/${PN}
	touch ${ED}/var/lib/${PN}/.keep_db_folder
}
