# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$
#
# Note: place jquery javascripts directly in this build
#       there's no sense in making this shared code, because
#	newer versions of jquery are not compatible
#

EAPI="5"

inherit eutils perl-module

MY_PV=${PV/_*/}
DESCRIPTION="Excito B3 administrative scripts"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/b/${PN}/${PN}_${MY_PV}.tar.gz
	http://code.jquery.com/jquery-1.4.2.js
	http://code.jquery.com/ui/1.8.12/jquery-ui.js?1.8.12"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE="+apache2 nginx"

REQUIRED_USE="^^ ( apache2 nginx )"

DEPEND="
	app-admin/bubba-backend
	dev-ruby/coffee-script
	dev-perl/Locale-PO
	dev-perl/Getopt-Long-Descriptive
"

#	dev-java/jquery
#	dev-java/jquery-ui

RDEPEND="
	dev-lang/php[cgi,fpm,sockets,json,xml,gd,pdo,crypt,imap]
	apache2? ( dev-lang/php[apache2] )
	apache2? ( www-servers/apache[apache2_modules_proxy,apache2_modules_proxy_fcgi,apache2_modules_proxy_http,apache2_modules_rewrite] )
	nginx? ( www-servers/nginx[nginx_modules_http_proxy,nginx_modules_http_rewrite,nginx_modules_http_fastcgi,nginx_modules_http_access,nginx_modules_http_auth_basic,nginx_modules_http_referer] )
	www-servers/spawn-fcgi
	www-apps/codeigniter-bin

"

S=${WORKDIR}/${PN}

pkg_setup() {
	ebegin "checking for coffee"
	# verify that the coffee command is available during install
	if which coffee 1>/dev/null  2>/dev/null ; then
		eend 0
	else
		eend 1 ""
		ewarn "attempting to install coffee"
		npm install -g coffee-script
	fi
	which coffee 1>/dev/null  2>/dev/null || die "failed to install coffee - please verify npm command"
}


src_prepare() {
	patch -p1 < ${FILESDIR}/${P}.patch

	use apache2 && sed -i "s/www-data/apache/" spawn-php
	use nginx && sed -i "s/www-data/nginx/" spawn-php

	echo "date.timezone=\"`cat /etc/timezone`\"" >> php5-cgi.conf
	echo "short_opentag=On" >> php5-cgi.conf

}


src_compile() {
	# There is an issue with the msgfmt check format routine always
	# comparing the translations to msgid_plural
	find po -type f -exec sed -i "s/\([^\%]\)\%d /\1@NUMBER@ /" {} \;
	emake DESTDIR=${D}

	find po -type f -exec sed -i "s/@NUMBER@/\%d/" {} \;

}


src_install() {
	emake install DESTDIR=${D}
	insinto /opt/bubba/web-admin
	doins -r admin
#	dosym /usr/share/javascript/jquery/jquery.js /opt/bubba/web-admin/admin/views/default/_js/jquery.js
#	dosym /usr/share/javascript/jquery-ui/jquery-ui.js /opt/bubba/web-admin/admin/views/default/_js/jquery-ui.js
	insinto /opt/bubba/web-admin/admin/views/default/_js
	newins ${DISTDIR}/jquery-1.4.2.js jquery.js
	newins ${DISTDIR}/jquery-ui.js\?1.8.12 jquery-ui.js


	PHP_CLI_INI_PATH=$(php -n --ini | grep -v "(none)" | awk '{print $NF}')
	PHP_CGI_INI_PATH=$(echo ${PHP_CLI_INI_PATH} | sed "s/cli/cgi/")
	PHP_APACHE_INI_PATH=$(echo ${PHP_CLI_INI_PATH} | sed "s/cli/apache2/")

	insinto ${PHP_CGI_INI_PATH}/ext
	newins php5-cgi.conf bubba-admin.ini
	dosym ${PHP_CGI_INI_PATH}/ext/bubba-admin.ini ${PHP_CGI_INI_PATH}/ext-active/bubba-admin.ini

	if use apache2; then
		insinto ${PHP_APACHE_INI_PATH}/ext
		newins php5-apache.conf bubba-admin.ini
		dosym ${PHP_APACHE_INI_PATH}/ext/bubba-admin.ini ${PHP_APACHE_INI_PATH}/ext-active/bubba-admin.ini

		insinto /etc/apache2/vhosts.d
		newins ${FILESDIR}/apache.conf bubba.conf
	fi

	if use nginx; then
		insinto /etc/nginx/vhosts.d
		newins ${FILESDIR}/nginx.conf bubba.conf
	fi


	insinto /etc/bubba
	doins lite_php_browscap.ini

	dodir /var/log/web-admin 

	exeinto /opt/bubba/sbin
	doexe spawn-php

	newinitd ${FILESDIR}/bubba-adminphp.initd bubba-adminphp

	dodoc "${S}/debian/copyright" "${S}/debian/changelog"
	insinto /usr/share/doc/${PF}/sample
	docompress -x /usr/share/doc/${PF}/sample
	doins php5-cgi.conf php5-apache.conf php5-xcache.ini ${FILESDIR}/*.conf ${FILESDIR}/*.initd
}


pkg_postinst() {
	elog ""

}


