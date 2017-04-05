# Copyright 2017 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils systemd toolchain-funcs

#EGIT_REPO_URI="git://github.com/domoticz/domoticz.git"
COMMIT="fbe8c52"
CTIME="2017-04-05 09:15:34 +0200"

SRC_URI="https://github.com/domoticz/domoticz/archive/${COMMIT}.zip -> ${PN}-${PV}.zip"
RESTRICT="mirror"
DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="systemd telldus openzwave python"


RDEPEND="net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost
	sys-libs/zlib
	telldus? ( app-misc/telldus-core )
	openzwave? ( dev-libs/openzwave )
	python? ( dev-lang/python )
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


	# Hard disable static boost:
	sed \
		-e "s:\${USE_STATIC_BOOST}:OFF:" \
		-i CMakeLists.txt

	use python || {
		sed \
		-e "/option(USE_PYTHON_PLUGINS/c option(USE_PYTHON_PLUGINS NO)" \
		-i CMakeLists.txt
	}

}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DCMAKE_INSTALL_PREFIX="/opt/domoticz"
		-DBoost_INCLUDE_DIR="OFF"
		-DUSE_STATIC_BOOST="OFF"
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

