# Copyright 2026 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="8"

inherit cmake

#EGIT_REPO_URI="https://github.com/domoticz/libwebem.git"
#EGIT_BRANCH="master"
COMMIT="9010adf"
CTIME="2026-03-21 19:30:59 +0100"

SRC_URI="https://github.com/domoticz/${PN}/archive/${COMMIT}.tar.gz -> ${PN}-${PV}.tar.gz"
RESTRICT="mirror"
DESCRIPTION="Webserver library for Domoticz Home automation system"
HOMEPAGE="http://domoticz.com/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~x86"
IUSE=""

RDEPEND="
	 dev-libs/boost
	 dev-libs/jsoncpp
	 dev-libs/openssl
	 sys-libs/zlib[minizip]
	 >=dev-cpp/jwt-cpp-0.7.1[picojson]
"

DEPEND="${RDEPEND}"

CMAKE_IN_SOURCE_BUILD=yes

src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-* ${S}
}


src_prepare() {
	eapply_user

	# webem: cmake find_package does not work with jsoncpp and minizip
	sed \
	  -e "s/find_package(jsoncpp QUIET)/find_package(PkgConfig)\n pkg_check_modules(jsoncpp REQUIRED jsoncpp)/" \
	  -e "s/jsoncpp_FOUND)/jsoncpp_FOUND)\n target_include_directories(webem PRIVATE \${jsoncpp_INCLUDE_DIRS})\n target_link_libraries(webem PRIVATE \${JSONCPP_LIBRARIES})/" \
	  -e "/jsoncpp_lib/d" \
	  -e "s/find_package(minizip QUIET)/find_package(PkgConfig)\n pkg_check_modules(minizip REQUIRED minizip)/" \
	  -e "s/minizip::minizip/minizip/" \
	  -e "s/jwt-cpp_FOUND/1/" \
	  -e "/target_link_libraries(webem PRIVATE jwt-cpp::jwt-cpp)/d" \
	  -i ${S}/CMakeLists.txt

	cmake_src_prepare

}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	insinto /var/lib/${PN}
	touch ${ED}/var/lib/${PN}/.keep_db_folder

	dodoc LICENSE docs/INTEGRATION.md
}

