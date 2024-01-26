# Copyright 2015-2020 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

LUA_VR="5.3.6"


inherit cmake git-r3 systemd

EGIT_REPO_URI="https://github.com/domoticz/domoticz.git"
EGIT_BRANCH="development"

LUA_V="${LUA_VR:0:3}"
PKG_LUA="lua-${LUA_VR}.tar.gz"
SRC_URI="internal-lua? ( http://www.lua.org/ftp/${PKG_LUA} )"


DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="systemd telldus openzwave python i2c +spi +internal-lua examples"

RDEPEND="net-misc/curl
	 dev-libs/libusb
	 dev-libs/libusb-compat
	 dev-embedded/libftdi
	 dev-db/sqlite
	 dev-libs/boost
	 sys-libs/zlib[minizip]
	 !internal-lua? ( dev-lang/lua:5.2 )
	 app-misc/mosquitto
	 dev-db/sqlite
	 telldus? ( app-misc/telldus-core )
	 openzwave? ( dev-libs/openzwave )
	 python? ( dev-lang/python )
	 dev-libs/openssl
	 dev-libs/cereal
	 dev-libs/jsoncpp
"

DEPEND="${RDEPEND}"


CMAKE_IN_SOURCE_BUILD=yes


make_lua() {
	einfo "building Lua ${LUA_VR}"
	cd "${WORKDIR}/lua-${LUA_VR}"
	emake -s linux
	mv "src/liblua.a" "${S}/liblua${LUA_V}.a"
	cd - &>/dev/null
}

src_unpack() {
	git-r3_src_unpack
	use internal-lua && unpack ${PKG_LUA}
}

src_prepare() {
	eapply_user

	# reset all static and runtime folder dynamic linking to off
	sed -e "s/option\(.*\)YES)/option\1NO)/" -i ${S}/CMakeLists.txt
	sed -e "s/option\(.*\)ON)/option\1NO)/" -i ${S}/CMakeLists.txt

	# disable automatic scanning for Telldus
	use telldus || {
		sed \
		  -e "s/libtelldus-core.so/libtelldus-core.so.invalid/" \
		  -e "/Found telldus/d" \
		  -e "/find_path(TELLDUSCORE_INCLUDE/c  set(TELLDUSCORE_INCLUDE NO)" \
		  -e "/Not found telldus-core/c  message(STATUS \"tellstick support disabled\")" \
		  -i ${S}/CMakeLists.txt
	}

	# disable automatic scanning for OpenZWave
	use openzwave || {
		sed \
		  -e "/pkg_check_modules(OPENZWAVE/cset(OPENZWAVE_FOUND NO)" \
		  -e "s/==== OpenZWave.*!/OpenZWave support disabled/" \
		  -i ${S}/CMakeLists.txt
	}

	# Lua: https://bugs.gentoo.org/407091
	if (use internal-lua); then
		ln -s ${WORKDIR}/lua-${LUA_VR}/src lua${LUA_V}
		sed \
		  -e "s/liblua${LUA_V}\.a/liblua${LUA_V}.a HINTS \"\${CMAKE_PREFIX_PATH}\"/" \
		  -e "s/lua${LUA_V}\/lua\.h/lua${LUA_V}\/lua.h HINTS \"\${CMAKE_PREFIX_PATH}\"/" \
		  -i ${S}/CMakeLists.txt
		if [[ -n "${CHOST}" ]]; then
			sed \
			  -e "s/gcc/${CHOST}-gcc/" \
			  -i ${S}/lua${LUA_V}/Makefile
		fi
	else
		einfo "Patch code to allow running with Lua 5.2"
		sed \
		  -e "s/5\.3/5.2/g" \
		  -e "/find_package(Lua/c  find_package(PkgConfig)\n  pkg_search_module(LUA lua5.2>=5.2 lua>=5.2 lua-5.2)" \
		  -i ${S}/CMakeLists.txt
		eapply ${FILESDIR}/Do_not_use_the_long_long_integer_type_with_LUA_prior_to_5.3.patch
	fi

	# fix placeholder ambiguation in beta code
	sed -e "s/c++11/c++14/" -i ${S}/CMakeLists.txt
	grep -r -m1 "using namespace std::placeholders" | cut -d: -f1 | while read FILE; do
		grep -q -m1 "BOOST_BIND_NO_PLACEHOLDERS" "${FILE}" || sed -e "1s/^/#define BOOST_BIND_NO_PLACEHOLDERS\n/" -i "${FILE}"
	done

	cmake_src_prepare

}

src_configure() {

	# If we are integrating Lua in our build we need to compile the library before
	# attempting to configure Domoticz
	use internal-lua && make_lua

	# static linking of `builtin` submodules is broken
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DCMAKE_INSTALL_PREFIX="/opt/domoticz"
		-DUSE_PRECOMPILED_HEADER="YES"
		-DUSE_PYTHON=$(usex python)
		-DINCLUDE_LINUX_I2C=$(usex i2c)
		-DINCLUDE_SPI=$(usex spi)
	)

	use internal-lua && mycmakeargs+=(
		-DUSE_LUA_STATIC="YES"
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use systemd ; then
		systemd_newunit "${FILESDIR}/${PN}.service" "${PN}.service"
		systemd_install_serviced "${FILESDIR}/${PN}.service.conf"
	else
		newinitd "${FILESDIR}/${PN}.init.d" ${PN}
		newconfd "${FILESDIR}/${PN}.conf.d" ${PN}
	fi

	insinto /var/lib/${PN}
	touch ${ED}/var/lib/${PN}/.keep_db_folder
	doins ttnmqtt_aliasses.json

	dodoc History.txt License.txt

	# compress static web content
	find ${ED} -name "*.css" -exec gzip -9 {} \;
	find ${ED} -name "*.js" -exec gzip -9 {} \;
	find ${ED} -name "*.html" -exec sh -c 'grep -q "<.--#embed" {} || gzip -9 {}' \;

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
