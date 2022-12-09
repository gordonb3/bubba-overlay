# Copyright 2015-2022 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

DESCRIPTION="CodeIgniter PHP framework for full-featured web applications"
SRC_URI="https://github.com/bcit-ci/CodeIgniter/archive/${PV}.zip"
RESTRICT="mirror"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""


MY_PN="CodeIgniter"
S="${WORKDIR}/${MY_PN}-${PV}"
LICENSE="MIT"


# Installation dependencies.
DEPEND=""

# Runtime dependencies.
RDEPEND=">=dev-lang/php-5.1.6"

src_install() {
	find -name index.html -exec rm {} \;
	dodir /opt/codeigniter
	find ${S} -maxdepth 2 -type d -name system -exec cp -a {} ${D}/opt/codeigniter/ \;
	dodoc license.txt
}

