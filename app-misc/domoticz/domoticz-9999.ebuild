# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils git-r3 systemd

EGIT_REPO_URI="https://github.com/domoticz/domoticz.git"
EGIT_BRANCH="development"

DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="systemd telldus openzwave python i2c +spi static-libs examples"

RDEPEND="net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost[static-libs=]
	!static-libs?
	( sys-libs/zlib[minizip]
	  dev-lang/lua:5.2
	  app-misc/mosquitto
	  dev-db/sqlite
	)
	telldus? ( app-misc/telldus-core )
	openzwave? ( dev-libs/openzwave )
	python? ( dev-lang/python )
	dev-libs/openssl[static-libs=]
	dev-libs/cereal
	dev-libs/jsoncpp
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
		-i ${S}/CMakeLists.txt
	}

	use openzwave || {
		sed \
		-e "/pkg_check_modules(OPENZWAVE/cset(OPENZWAVE_FOUND NO)" \
		-e "s/==== OpenZWave.*!/OpenZWave support disabled/" \
		-i ${S}/CMakeLists.txt
	}

	einfo "Patch code to allow running with Lua 5.2"

	sed \
	-e "s/5\.3/5.2/g" \
	-e "/find_package(Lua/c  find_package(PkgConfig)\n  pkg_search_module(LUA lua5.2>=5.2 lua>=5.2 lua-5.2)" \
	-i ${S}/CMakeLists.txt
	epatch ${FILESDIR}/Do_not_use_the_long_long_integer_type_with_LUA_prior_to_5.3.patch

	# domoticz does not build subdirectories by default
	sed -e "s/EXCLUDE_FROM_ALL//" -i ${S}/CMakeLists.txt

	# fix placeholder ambiguation in beta code
	sed -e "s/c++11/c++14/" -i ${S}/CMakeLists.txt
	grep -r -m1 "using namespace std::placeholders" | cut -d: -f1 | while read FILE; do
		grep -q -m1 "BOOST_BIND_NO_PLACEHOLDERS" "${FILE}" || sed -e "1s/^/#define BOOST_BIND_NO_PLACEHOLDERS\n/" -i "${FILE}"
	done

	cmake-utils_src_prepare
}

src_configure() {
	# linking of `builtin` submodules is broken in the CMake file
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
		-DUSE_BUILTIN_MINIZIP="OFF"
		-DUSE_BUILTIN_MQTT="OFF"
		-DUSE_BUILTIN_SQLITE="OFF"
		-DUSE_BUILTIN_JSONCPP="OFF"
		-DGIT_SUBMODULE="OFF"
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

	dodoc History.txt License.txt

	# compress static web content
	find ${ED} -name "*.css" -exec gzip -9 {} \;
	find ${ED} -name "*.js" -exec gzip -9 {} \;
	find ${ED} -name "*.html" -exec sh -c 'grep -q "<\!--#embed" {} || gzip -9 {}' \;

	# cleanup examples and non functional scripts
	rm -rf ${ED}/opt/${PN}/{updatedomo,server_cert.pem,History.txt,License.txt}
	rm -rf ${ED}/opt/${PN}/scripts/{update_domoticz,restart_domoticz,download_update.sh,_domoticz_main*,logrotate}
	use examples || {
		rm -rf ${ED}/opt/${PN}/scripts/{dzVents/examples,lua/*demo.lua,python/*demo.py,lua_parsers/example*,*example*}
		rm -rf ${ED}/opt/${PN}/plugins/examples
	}
	rm -rf ${ED}/opt/${PN}/dzVents/.gitignore
	find ${ED}/opt/${PN}/scripts -empty -type d -exec rmdir {} \;

	# move scripts to /var/lib/domoticz
	mv ${ED}/opt/${PN}/scripts ${ED}/var/lib/${PN}/
	#dosym /var/lib/${PN}/scripts /opt/${PN}/scripts
}


pkg_postinst() {
	havescripts=$(find /opt/${PN} -maxdepth 1 -type d -name scripts)
	if [ ! -z "${havescripts}" ]; then
		mv /opt/${PN}/scripts/* /var/lib/${PN}/scripts/
		rmdir /opt/${PN}/scripts
	fi
	ln -s /var/lib/${PN}/scripts /opt/${PN}/scripts
}

pkg_prerm() {
	find /opt/${PN} -type l -exec rm {} \;
}
