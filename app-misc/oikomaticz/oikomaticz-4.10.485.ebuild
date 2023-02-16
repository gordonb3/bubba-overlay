# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit cmake systemd

#EGIT_REPO_URI="git://github.com/gordonb3/${PN}.git"
COMMIT="f4908da4"
CTIME="2023-02-16 13:24:55 +0100"

SRC_URI="https://github.com/gordonb3/${PN}/archive/${COMMIT}.zip -> ${PN}-${PV}.zip"
RESTRICT="mirror"
DESCRIPTION="Home automation system"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~x86"
IUSE="systemd telldus openzwave python i2c +spi gpio +internal-lua examples"

VMAJOR=${PV:0:1}
SLOT="0/${VMAJOR}"

RDEPEND="net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost
	sys-libs/zlib[minizip]
	!internal-lua? ( dev-lang/lua:5.3 )
	app-misc/mosquitto[srv]
	net-dns/c-ares
	dev-db/sqlite
	telldus? ( app-misc/telldus-core )
	openzwave? ( dev-libs/openzwave )
	python? ( >=dev-lang/python-3.4 )
	dev-libs/openssl
"

DEPEND="${RDEPEND}"

BDEPEND="${RDEPEND}
	dev-util/cmake
"

CMAKE_IN_SOURCE_BUILD=yes

src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-* ${S}
}

src_prepare() {
	eapply_user

	# the project cmake file takes the application version from the Git project revision
	# we can't use that here because the snapshot does not contain the Git header files
	ProjectHash=${COMMIT:0:7}
	ProjectRevision=${PV:2}
	ProjectDate=$(date -d "${CTIME}" +"%s")
	elog "building ${PN} version ${PV}, using Git commit \"${ProjectHash}\" from ${CTIME}"
	echo -e "#pragma once\n#define VERSION_STRING \"${VMAJOR}.\"\n#define APPVERSION \"${ProjectRevision}\"\n#define APPHASH \"${ProjectHash}\"\n#define APPDATE ${ProjectDate}\n" > appversion.h
	echo 'execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different appversion.h appversion.h.txt)' > getgit.cmake
	sed \
	  -e "/^Gitversion_GET_REVISION/cset(ProjectRevision ${ProjectRevision})" \
	  -e "/^MATH(EXPR ProjectRevision/d" \
	  -e "s/^.*+2107.*$/#/" \
	  -i CMakeLists.txt


	# reset all static and runtime folder dynamic linking to off
	sed -e "s/option\(.*\)YES)/option\1NO)/" -i ${S}/CMakeLists.txt
	sed -e "s/option\(.*\)YES)/option\1NO)/" -i ${S}/libs/CMakeLists.txt

	# disable automatic scanning for Telldus
	use telldus || {
		sed \
		  -e "s/libtelldus-core.so/libtelldus-core.so.invalid/" \
		  -e "/Found telldus/d" \
		  -e "/find_path(TELLDUSCORE_INCLUDE/c  set(TELLDUSCORE_INCLUDE NO)" \
		  -e "/Not found telldus-core/c  message(STATUS \"tellstick support disbled\")" \
		  -i CMakeLists.txt
	}

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DCMAKE_INSTALL_PREFIX="/opt/${PN}"
		-DUSE_PRECOMPILED_HEADER="YES"
		-DWITH_PYTHON=$(usex python)
		-DWITH_LINUX_I2C=$(usex i2c)
		-DWITH_SPI=$(usex spi)
		-DWITH_GPIO=$(usex gpio)
		-DWITH_OPENZWAVE=$(usex openzwave)
		-DWITHOUT_OLDDB_SUPPORT=yes
	)

	use internal-lua && mycmakeargs+=(
		-DUSE_BUILTIN_LUA="YES"
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile
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

	dodoc History.txt License.txt

	# compress static web content
	find ${ED}/opt/${PN}/www -name "*.css" -exec gzip -9 {} \;
	find ${ED}/opt/${PN}/www -name "*.js" -exec gzip -9 {} \;
	find ${ED}/opt/${PN}/www -name "*.html" -exec sh -c 'grep -q "<\!--#embed" {} 2>/dev/null || gzip -9 {}' \;

	# cleanup examples and non functional scripts
	rm -rf ${ED}/opt/${PN}/{server_cert.pem,License.txt}
	rm -rf ${ED}/var/lib/${PN}/scripts/{_oikomaticz_main*,logrotate}
	use examples || {
		rm -rf ${ED}/var/lib/${PN}/scripts/{dzVents/examples,lua/*demo.lua,python/*demo.py,lua_parsers/example*,*example*}
		rm -rf ${ED}/var/lib/${PN}/plugins/examples
	}
	find ${ED}/var/lib/${PN}/scripts -empty -type d -exec rm -rf {} \;
}


pkg_postinst() {
	havescripts=$(find ${EROOT}/opt/${PN} -maxdepth 1 -type d -name scripts)
	if [ ! -z "${havescripts}" ]; then
		mv ${EROOT}/opt/${PN}/scripts/* ${EROOT}/var/lib/${PN}/scripts/
		rmdir ${EROOT}/opt/${PN}/scripts
	fi

	# backward compatibility
	ln -s ${EROOT}/var/lib/${PN}/scripts ${EROOT}/opt/${PN}/scripts
}

pkg_prerm() {
	find ${EROOT}/opt/${PN} -type l -exec rm {} \;
}

