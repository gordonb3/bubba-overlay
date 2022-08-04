# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit cmake

DESCRIPTION="Library to control a Telldus TellStick"
HOMEPAGE="http://www.telldus.com/"
SRC_URI="http://download.telldus.com/TellStick/Software/${PN}/${PF}.tar.gz"
RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""

DEPEND="dev-libs/confuse
	dev-embedded/libftdi
"

RDEPEND="${DEPEND}"

S=${WORKDIR}/${PF}
CMAKE_IN_SOURCE_BUILD=yes

src_prepare() {
	eapply_user

	# Fix missing pthread link flag in tdtool and tdadmin targets
	sed -e "s/libtelldus-core\.so/libtelldus-core.so\n\t\tpthread/" \
	    -i ${S}/tdtool/CMakeLists.txt
	sed -e "s/libtelldus-core\.so/libtelldus-core.so\n\t\tpthread/" \
	    -i ${S}/tdadmin/CMakeLists.txt

	# ftdi library has a '1' appended to it
	sed -e "s/ftdi)/ftdi1)/" \
	    -i ${S}/service/CMakeLists.txt

	# doxyfile generation is broken in these sources
	sed -e "s/FIND_PACKAGE(Doxygen)/SET(DOXYGEN_FOUND FALSE)/" \
	    -i ${S}/CMakeLists.txt

	# gcc 11 fix
	sed -e "s/cfg > 0/cfg != nullptr/" \
	    -i ${S}/service/SettingsConfuse.cpp


	cmake_src_prepare
}


src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_INSTALL_PREFIX="/usr"
	)

	cmake_src_configure
}


src_compile() {
	# compile telldus-core target first to fix dependency issue with -j > 1
	cmake_src_compile telldus-core

	cmake_src_compile
}


src_install() {
	cmake_src_install
}
