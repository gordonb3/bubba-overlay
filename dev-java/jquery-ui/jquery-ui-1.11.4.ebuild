# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
DESCRIPTION="a fast and concise JavaScript Library"
HOMEPAGE="http://jquery.com"
SRC_URI="http://code.jquery.com/ui/${PV}/${PN}.js
	http://code.jquery.com/ui/${PV}/${PN}.min.js"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~arm"
RESTRICT="mirror"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}"

src_unpack() {
	cp "${DISTDIR}/${PN}.js" "${S}/${P}.js"
	cp "${DISTDIR}/${PN}.min.js" "${S}/${P}.min.js"
}

src_install() {
	insinto "/usr/share/javascript/${PN}/"
	doins "${P}.js" "${P}.min.js"
	dosym /usr/share/javascript/${PN}/${P}.js /usr/share/javascript/${PN}/${PN}.js
	dosym /usr/share/javascript/${PN}/${P}.min.js /usr/share/javascript/${PN}/${PN}.min.js
}
