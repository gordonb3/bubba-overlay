# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

DESCRIPTION="Excito B2 manual"
HOMEPAGE="http://www.excito.com/"

if [[ ${PR} == "r0" ]] ; then
	SRC_URI="https://github.com/gordonb3/${PN}/archive/${PV}.tar.gz"
else
	REV=${PR/r/rc}
	SRC_URI="https://github.com/gordonb3/${PN}/archive/${PV}_${REV}.tar.gz"
	S=${WORKDIR}/${PN}-${PV}_${REV}
fi


RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~ppc"


src_install() {
	insinto /opt/bubba/manual
	doins -r manual/*
	dodoc debian/copyright debian/changelog
}
