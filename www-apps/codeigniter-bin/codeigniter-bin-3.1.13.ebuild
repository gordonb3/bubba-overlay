# Copyright 2024 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="8"

DESCRIPTION="CodeIgniter PHP framework for full-featured web applications"
SRC_URI="https://github.com/bcit-ci/CodeIgniter/archive/${PV}.tar.gz -> ${PF}.tar.gz"
RESTRICT="mirror"
SLOT="0/3"
KEYWORDS="~arm ~ppc"
IUSE=""

PATCHES=(
	"${FILESDIR}/ci3.patch"
)

MY_PN="CodeIgniter"
S="${WORKDIR}/${MY_PN}-${PV}"
LICENSE="MIT"


# Installation dependencies.
DEPEND=""

# Runtime dependencies.
RDEPEND=">=dev-lang/php-5.6"

src_install() {
	find -name index.html -exec rm {} \;
	dodir /opt/codeigniter
	find ${S} -maxdepth 2 -type d -name system -exec cp -a {} ${D}/opt/codeigniter/ \;
	dodoc license.txt
}

