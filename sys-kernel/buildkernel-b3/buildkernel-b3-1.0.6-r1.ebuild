# ebuild for buildkernel-b3 (an Excito B3 kernel buildscript)
# Copyright (c) 2015 sakaki <sakaki@deciban.com>
# License: GPL v2
#
# Revison 2024 gordonb3 <gordon@bosvangennip.nl>
#
# NO WARRANTY

EAPI=8


DESCRIPTION="Script to build a bootable Linux kernel for the Excito B3"
BASE_SERVER_URI="https://github.com/sakaki-"
HOMEPAGE="${BASE_SERVER_URI}/${PN}"
SRC_URI="${BASE_SERVER_URI}/${PN}/releases/download/${PV}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm"

RESTRICT="mirror"

PATCHES=(
	"${FILESDIR}/kernel_6.6_revised_dts_paths.patch"
)


DEPEND=">=app-shells/bash-4.2"
# we choose not to make gentoo-sources a hard dependency
RDEPEND="${DEPEND}
	>=sys-libs/ncurses-5.9-r2
	>=dev-embedded/u-boot-tools-2014.01"

# ebuild function overrides
src_install() {
	dosbin "${PN}"
	doman "${PN}.8"
}

