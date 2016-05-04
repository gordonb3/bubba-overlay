# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

MY_PN=${PN/bubba-//}mail
MY_P=${MY_PN}-${PV/_/-}

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="http://roundcube.net"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.tar.gz"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="amd64 arm ~hppa ppc ~ppc64 ~sparc x86"
IUSE="ldap -mysql postgres +sqlite ssl spell"
SLOT="0"

DEPEND=""

RDEPEND="
	${DEPEND}
	>=dev-lang/php-5.3[crypt,filter,gd,iconv,json,ldap?,pdo,postgres?,session,sockets,ssl?,unicode,xml]
	>=dev-php/PEAR-Auth_SASL-1.0.3
	>=dev-php/PEAR-Crypt_GPG-1.3.2
	>=dev-php/PEAR-Mail_Mime-1.8.1
	>=dev-php/PEAR-Net_IDNA2-0.1.1
	>=dev-php/PEAR-Net_SMTP-1.4.2
	>=dev-php/PEAR-Net_Sieve-1.3.2
	>=dev-php/PEAR-Net_Socket-1.0.14
	mysql? ( || ( dev-lang/php[mysql] dev-lang/php[mysqli] ) )
	spell? ( dev-lang/php[curl,spell] )
	sqlite? ( dev-lang/php[sqlite] )
	virtual/httpd-php
"

S=${WORKDIR}/${MY_P}

src_prepare() {
	# Remove bundled PEAR packages
	rm -r program/lib/{Auth,Crypt,Mail,Net,PEAR*} || die
}

src_install() {
	dodoc CHANGELOG INSTALL README.md UPGRADING

	insinto /opt/roundcube/htdocs
	doins -r [[:lower:]]* SQL
	doins .htaccess

	fowners apache.apache /opt/roundcube/htdocs/logs
	fowners apache.apache /opt/roundcube/htdocs/temp

	insinto /var/log/roundcube
	fowners apache.apache /var/log/roundcube

	insinto /var/lib/roundcube
	fowners apache.apache /var/lib/roundcube
}

pkg_postinst() {

	if [ ! -e /opt/roundcube/htdocs/config/config.inc.php ]; then
		cp ${FILESDIR}/bubba.conf /opt/roundcube/htdocs/config/config.inc.php
		elog "copy bubba default config"
		des_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9+*%&?!$-_=' | fold -w 24 | head -n 1)
		elog "generated new secret key: ${des_key}"
		sed -i "/des_key/d" /opt/roundcube/htdocs/config/config.inc.php
		sed -i "/^?>/d" /opt/roundcube/htdocs/config/config.inc.php
		echo "\$config['des_key'] = '${des_key}';" >> /opt/roundcube/htdocs/config/config.inc.php
		echo "?>" >> /opt/roundcube/htdocs/config/config.inc.php
	fi

	ewarn "When upgrading from <= 0.9, note that the old configuration files"
	ewarn "named main.inc.php and db.inc.php are deprecated and should be"
	ewarn "replaced with one single config.inc.php file."
	ewarn "Run the ./bin/update.sh script to convert those"
	ewarn "or manually merge the files."
	ewarn "The new config.inc.php should only contain options that"
	ewarn "differ from the ones listed in defaults.inc.php."
}
