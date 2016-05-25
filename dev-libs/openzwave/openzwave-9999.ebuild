# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils git-r3

EGIT_REPO_URI="https://github.com/OpenZWave/open-zwave.git"

DESCRIPTION="free software library that interfaces with selected Z-Wave PC controllers"
HOMEPAGE="http://www.openzwave.net/"

LICENSE="GPL-3 Apache-2.0"
SLOT="0"
KEYWORDS=""
IUSE="-examples -htmldoc"

DEPEND="htmldoc? ( app-doc/doxygen  media-gfx/graphviz )"

DEPEND=""


src_prepare() {
        if ! use examples; then
                sed -i -e "/examples/d" ${S}/Makefile
        fi
}

src_install() {
        if use htmldoc; then
                emake DESTDIR="${D}" PREFIX="/usr" install
        else
            	emake DESTDIR="${D}" PREFIX="/usr" DOXYGEN='' install
        fi
}

