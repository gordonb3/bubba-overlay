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
IUSE="systemd telldus openzwave python i2c +spi static-libs"

RDEPEND="net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost[static-libs=]
	sys-libs/zlib[minizip,static-libs=]
	telldus? ( app-misc/telldus-core )
	openzwave? ( dev-libs/openzwave[static-libs=] )
	python? ( dev-lang/python )
	dev-libs/openssl[static-libs=]
"

DEPEND="${RDEPEND}
	dev-util/cmake"

src_prepare() {
	# link build directory
	ln -s ${S} ${WORKDIR}/${PF}_build

	use telldus || {
		sed \
		-e "s/libtelldus-core.so/libtelldus-core.so.invalid/" \
		-e "/Found telldus/d" \
		-e "/find_path(TELLDUSCORE_INCLUDE/c  set(TELLDUSCORE_INCLUDE NO)" \
		-e "/Not found telldus-core/c  message(STATUS \"tellstick support disbled\")" \
		-i CMakeLists.txt
	}

	use openzwave || {
		sed \
		-e "/pkg_check_modules(OPENZWAVE/cset(OPENZWAVE_FOUND NO)" \
		-e "s/==== OpenZWave.*!/OpenZWave support disabled/" \
		-i CMakeLists.txt
	}

}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DCMAKE_INSTALL_PREFIX="/opt/domoticz"
		-DBoost_INCLUDE_DIR="OFF"
		-DUSE_STATIC_BOOST=$(usex static-libs)
		-DUSE_PYTHON=$(usex python)
		-DINCLUDE_LINUX_I2C=$(usex i2c)
		-DINCLUDE_SPI=$(usex spi)
		-DUSE_STATIC_OPENZWAVE=$(usex static-libs)
		-DUSE_OPENSSL_STATIC=$(usex static-libs)
		-DUSE_STATIC_LIBSTDCXX=$(usex static-libs)
		-DUSE_BUILTIN_MINIZIP=no
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
