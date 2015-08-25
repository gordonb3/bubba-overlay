# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="PHP bindig for Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/libb/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="apache2"

DEPEND=""

RDEPEND="${DEPEND}
	dev-libs/libbubba-info
"


S=${WORKDIR}/${PN}


src_prepare() {
	# Strange error in source file
	sed -i "s/^static function_entry/zend_function_entry/" -i bubba_info.c
	phpize
}

src_compile() {
	emake LIBTOOL="/usr/bin/libtool --tag=CC"
}


src_install() {
        emake LIBTOOL="/usr/bin/libtool --tag=CC" INSTALL_ROOT="${ED}" install
	dodoc debian/changelog debian/copyright
	insinto /usr/share/doc/${PF}/sample
	docompress -x /usr/share/doc/${PF}/sample
	doins bubbainfo.ini

	find /etc/php -name ext | while read extension_dir; do
		insinto ${extension_dir}
		doins bubbainfo.ini
		if [[ ${extension_dir} =~ fpm* ]]; then
			dosym ${extension_dir}/bubbainfo.ini ${extension_dir}-active/bubbainfo.ini
		fi
		if [[ ${extension_dir} =~ apache* ]]; then
			if use apache2 ; then
				dosym ${extension_dir}/bubbainfo.ini ${extension_dir}-active/bubbainfo.ini
			fi
		fi
	done

	
}


