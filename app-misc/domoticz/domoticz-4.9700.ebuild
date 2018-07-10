# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils systemd toolchain-funcs

#EGIT_REPO_URI="git://github.com/domoticz/domoticz.git"
COMMIT="a3a45906"
CTIME="2018-06-23 16:24:51 +0200"

SRC_URI="https://github.com/domoticz/domoticz/archive/${COMMIT}.zip -> ${PN}-${PV}.zip"
RESTRICT="mirror"
DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~x86"
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
	  app-misc/mosquitto[srv]
	  net-dns/c-ares
	  dev-db/sqlite
	)
	telldus? ( app-misc/telldus-core )
	openzwave? ( dev-libs/openzwave )
	python? ( dev-lang/python )
	dev-libs/openssl[static-libs=]
"

DEPEND="${RDEPEND}
	dev-util/cmake
"

src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-* ${S}
}

src_prepare() {
	# link build directory
	ln -s ${S} ${WORKDIR}/${PF}_build


	# the project cmake file takes the application version from the Git project revision
	# we can't use that here because the snapshot does not contain the Git header files
	ProjectHash=${COMMIT:0:7}
	ProjectRevision=${PV:2}
	ProjectDate=$(date -d "${CTIME}" +"%s")
	elog "building ${PN} version ${ProjectRevision}, using Git commit \"${ProjectHash}\" from ${CTIME}"
	echo -e "#define APPVERSION ${ProjectRevision}\n#define APPHASH \"${ProjectHash}\"\n#define APPDATE ${ProjectDate}\n" > appversion.h
	echo 'execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different appversion.h appversion.h.txt)' > getgit.cmake
	sed \
		-e "/^Gitversion_GET_REVISION/cset(ProjectRevision ${ProjectRevision})" \
		-e "/^MATH(EXPR ProjectRevision/d" \
		-e "s/+2107/+0/" \
		-i CMakeLists.txt


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

	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DCMAKE_INSTALL_PREFIX="/opt/${PN}"
		-DUSE_STATIC_BOOST=$(usex static-libs)
		-DUSE_PYTHON=$(usex python)
		-DINCLUDE_LINUX_I2C=$(usex i2c)
		-DINCLUDE_SPI=$(usex spi)
		-DUSE_STATIC_OPENZWAVE=$(usex static-libs)
		-DUSE_OPENSSL_STATIC=$(usex static-libs)
		-DUSE_STATIC_LIBSTDCXX=$(usex static-libs)
		-DUSE_BUILTIN_ZLIB=$(usex static-libs)
		-DUSE_BUILTIN_MINIZIP=$(usex static-libs)
		-DUSE_BUILTIN_LUA=$(usex static-libs)
		-DUSE_BUILTIN_MQTT=$(usex static-libs)
		-DUSE_BUILTIN_SQLITE=$(usex static-libs)
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

