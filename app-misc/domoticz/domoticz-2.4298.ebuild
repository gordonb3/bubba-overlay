# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit cmake-utils eutils systemd toolchain-funcs

#EGIT_REPO_URI="git://github.com/domoticz/domoticz.git"
COMMIT="4ab7980d8e80e014ebd45a13ca389016e79c077d"
CTIME="2016-01-22 11:09:00 +0100"

SRC_URI="https://github.com/domoticz/domoticz/archive/${COMMIT}.zip -> ${PN}-${PV}.zip"
RESTRICT="mirror"
DESCRIPTION="Home automation system"
HOMEPAGE="http://domoticz.com/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="-staticboost systemd"

DEPEND="
	dev-util/cmake
"

RDEPEND="${DEPEND}
	net-misc/curl
	dev-libs/libusb
	dev-libs/libusb-compat
	dev-embedded/libftdi
	dev-db/sqlite
	dev-libs/boost
	sys-libs/zlib
"


src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-${COMMIT} ${S}
}

src_prepare() {
	# link build directory
	ln -s ${S} ${WORKDIR}/${PF}_build


	# the project cmake file takes the application version from the Git project revision
	# we can't use that here because the snapshot does not contain the Git header files
	ProjectHash=${COMMIT:0:7}
	ProjectRevision=${PV:2}
	ProjectDate=$(date -d "${CTIME}" +"%s")
	elog "building APPVERSION ${ProjectRevision}, APPHASH \"${ProjectHash}\", APPDATE ${CTIME}"
	echo -e "#define APPVERSION ${ProjectRevision}\n#define APPHASH \"${ProjectHash}\"\n#define APPDATE ${ProjectDate}\n" > appversion.h
	echo 'execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different appversion.h appversion.h.txt)' > getgit.cmake
	sed \
		-e "/^Gitversion_GET_REVISION/cset(ProjectRevision ${ProjectRevision})" \
		-e "/^MATH(EXPR ProjectRevision/d" \
		-i CMakeLists.txt


	# disable static boost:
	sed \
		-e "s:\${USE_STATIC_BOOST}:OFF:" \
		-i CMakeLists.txt


	# trying to use precompiled header on cross compiler spits out
	# a bunch of ugly messages
	if tc-is-cross-compiler ; then
		sed \
			-e "/^ADD_PRECOMPILED_HEADER/d" \
			-e "/\${_targetName}_gch/d" \
			-i CMakeLists.txt
	fi
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="/opt/domoticz"
		$(cmake-utils_use staticboost USE_STATIC_BOOST)
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
