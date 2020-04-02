# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"
PYTHON_COMPAT=( python2_7 )
inherit eutils distutils-r1

MY_PN=lib${PN}
PVMAIN=1.3
PVPERL=1.2
PVPHP=1.2
PVPY=1.0

DESCRIPTION="Bubba platform information library"
HOMEPAGE="http://www.excito.com/"
SRC_URI="
	http://b3.update.excito.org/pool/main/libb/${MY_PN}/${MY_PN}_${PVMAIN}.tar.gz
	perl? ( http://b3.update.excito.org/pool/main/libb/${MY_PN}-perl/${MY_PN}-perl_${PVPERL}.tar.gz )
	php? ( http://b3.update.excito.org/pool/main/libb/${MY_PN}-php/${MY_PN}-php_${PVPHP}.tar.gz )
	python? ( http://b3.update.excito.org/pool/main/p/python-${PN}/python-${PN}_${PVPY}.tar.gz )
"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="apache2 +php +perl python"

BLOCK_OLD_PACKAGES="
	!dev-perl/libbubba-info-perl
	!dev-php/libbubba-info-php
	!dev-python/python-bubba-info
"
DEPEND="
	${BLOCK_OLD_PACKAGES}
	perl? ( dev-lang/perl:= )
	php? ( dev-lang/php:= )
	python? ( dev-python/setuptools[${PYTHON_USEDEP}] )
"
RDEPEND="${DEPEND}"



src_unpack() {
	default
	ln -s ${WORKDIR}/${MY_PN}-${PVMAIN} ${S}
	use perl && ln -s ${WORKDIR}/${MY_PN}-perl* ${S}/perl
	use php && ln -s ${WORKDIR}/${MY_PN}-php* ${S}/php
	use python && cp -al ${WORKDIR}/python-${PN}*/*.py ${S}/
}


src_prepare() {
	sed -e "s/libtool --mode/libtool --tag=CC --mode/" -i Makefile
	use perl && sed -e "s/^\(\s*.ABSTRACT\)_FROM.*$/\1       => 'Perl extension for querying Bubba platform information',/" -i perl/Makefile.PL
	use php && sed -e "s/^static function_entry/zend_function_entry/" -i php/bubba_info.c
	use python && sed -e "s/python2.6/python2.7/" -i bubba-info.py
}


src_configure() {
	if use perl; then
		einfo "configure perl modules"
		cd perl
		perl Makefile.PL
		cd - &>/dev/null
	fi

	if use php; then
		einfo "configure php modules"
		cd php
		phpize
		CFLAGS="$CFLAGS -Wno-implicit-function-declaration" LDFLAGS="-Wl,-O1 -Wl,--as-needed -L${S}/.libs" ./configure
		cd - &>/dev/null
	fi
}


src_compile() {
	einfo "compile main library"
	LDFLAGS="-Wl,-O1" make all

	if use perl; then
		einfo "compile perl module"
		cd perl
		ln -s ${S}/bubba-info.h ./
		emake DESTDIR=${ED} OTHERLDFLAGS="-L../libbubba-info-1.3/.libs"
		cd - &>/dev/null
	fi

	if use php; then
		einfo "compile php module"
		cd php
		emake LIBTOOL="/usr/bin/libtool --tag=CC"
		cd - &>/dev/null
	fi

	if use python; then
		einfo "compile python module"
		python2 setup.py build
	fi
}


src_install() {
	einfo "install main library"
	make DESTDIR=${ED} install
	dodoc ${FILESDIR}/Changelog ${FILESDIR}/changelog.debian debian/copyright

	# remove static libs
	rm ${ED}/usr/lib/*.a ${ED}/usr/lib/*.la

	if use perl; then
		einfo "install perl module"
		cd perl
		emake DESTDIR=${ED} INSTALLDIRS=vendor install
		cd - &>/dev/null
	fi

	if use php; then
		einfo "install php module"
		cd php
		emake LIBTOOL="/usr/bin/libtool --tag=CC" INSTALL_ROOT="${ED}" install
		insinto /usr/share/doc/${PF}/phpsample
		docompress -x /usr/share/doc/${PF}/phpsample
		doins bubbainfo.ini

		php_versions=$(eselect php list fpm | grep "\[.\]" | awk '{printf ",*%s",$2}' | sed "s/^,//")
		eval find /etc/php/{$php_versions}/ -name ext | while read extension_dir; do
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
		cd - &>/dev/null
	fi

	if use python; then
		einfo "install python module"
		python2 setup.py install --root=${ED}
	fi
}

