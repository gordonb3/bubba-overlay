# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit git-r3

EGIT_REPO_URI="https://github.com/OpenZWave/open-zwave.git"

DESCRIPTION="free software library that interfaces with selected Z-Wave PC controllers"
HOMEPAGE="http://www.openzwave.net/"

LICENSE="GPL-3 Apache-2.0"
SLOT="0"
KEYWORDS=""
IUSE="-examples -htmldoc"

DEPEND="htmldoc? ( app-doc/doxygen  media-gfx/graphviz )"

RDEPEND=""

src_prepare() {
	eapply_user

	if ! use examples; then
		sed -i -e "/examples/d" ${S}/Makefile
	fi

	if ! use htmldoc; then
		sed -e "/^DOT /d" \
		sed -e "/^DOXYGEN /d" \
		    -i ${S}/cpp/build/support.mk
	fi

	# Portage does not set CROSS_COMPILE env var - use CHOST instead
	sed -e "s/CROSS_COMPILE)/CHOST)-/g" \
	    -i ${S}/cpp/build/support.mk

	# gcc 11 compile issue
	if (grep -q "NULL == group" ${S}/cpp/src/command_classes/AssociationCommandConfiguration.cpp); then
		sed -e "s/\(Group\*.*\);/if (\1)/" \
		    -e "/NULL == group/d" \
		    -i ${S}/cpp/src/command_classes/AssociationCommandConfiguration.cpp
	fi
}

src_compile() {
	emake DESTDIR="${D}" PREFIX="/usr"
}

src_install() {
	emake DESTDIR="${D}" PREFIX="/usr" install
}
