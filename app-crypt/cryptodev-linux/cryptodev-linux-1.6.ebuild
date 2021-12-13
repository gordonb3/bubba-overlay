# placed in Public Domain

EAPI="6"

inherit linux-mod

DESCRIPTION="Cryptodev-linux module"
HOMEPAGE="http://cryptodev-linux.org/"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND=""

MODULE_NAMES="cryptodev()"
BUILD_TARGETS="build"

src_prepare() {
	eapply_user

	eapply "${FILESDIR}"/${PN}-1.6-Replace_INIT_COMPLETION_with_reinit_completion.patch
}

src_install() {
	linux-mod_src_install

	insinto /usr/include/crypto
	doins crypto/cryptodev.h
}
