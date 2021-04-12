# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="6"

inherit cmake-utils eutils

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

src_prepare() {
	eapply_user

	ln -s ${S} ${S}_build

	# Fix missing pthread link flag in tdtool and tdadmin targets
	sed -i \
		-e "s/libtelldus-core\.so/libtelldus-core.so\n\t\tpthread/" \
		${S}/tdtool/CMakeLists.txt
	sed -i \
		-e "s/libtelldus-core\.so/libtelldus-core.so\n\t\tpthread/" \
		${S}/tdadmin/CMakeLists.txt
	cmake-utils_src_configure
}


src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE="Release"
		-DCMAKE_INSTALL_PREFIX="/usr"
	)

	cmake-utils_src_configure
}


src_compile() {
	# compile telldus-core target first to fix dependency issue with -j > 1
	cmake-utils_src_compile telldus-core

	cmake-utils_src_compile
}


src_install() {
	cmake-utils_src_install
}
