# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI=6

ORG_PN=${PN/bubba-//}
MY_PN=${PN/bubba-//}mail
MY_P=${MY_PN}-${PV/_/-}
MY_HTDOCSDIR="/opt/roundcube/htdocs"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="http://roundcube.net"
SRC_URI="https://github.com/${ORG_PN}/${MY_PN}/releases/download/${PV/_/-}/${MY_P}.tar.gz"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="amd64 arm x86"
SLOT="0"

IUSE="enigma ldap managesieve -mysql -postgres +sqlite ssl spell"
REQUIRED_USE="|| ( mysql postgres sqlite )"

DEPEND="|| ( virtual/httpd-cgi virtual/httpd-fastcgi )"

RDEPEND="
	${DEPEND}
        >=dev-lang/php-5.3.7[crypt,filter,gd,iconv,json,ldap?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml]
        >=dev-php/PEAR-Auth_SASL-1.0.6
        >=dev-php/PEAR-Mail_Mime-1.8.9
        >=dev-php/PEAR-Mail_mimeDecode-1.5.5
        >=dev-php/PEAR-Net_IDNA2-0.1.1
        >=dev-php/PEAR-Net_SMTP-1.6.2
        virtual/httpd-php
        enigma? ( >=dev-php/PEAR-Crypt_GPG-1.4.0 app-crypt/gnupg )
        ldap? ( >=dev-php/PEAR-Net_LDAP2-2.0.12 dev-php/PEAR-Net_LDAP3 )
        managesieve? ( >=dev-php/PEAR-Net_Sieve-1.3.2 )
        mysql? ( || ( dev-lang/php[mysql] dev-lang/php[mysqli] ) )
        spell? ( dev-lang/php[curl,spell] )
"

S=${WORKDIR}/${MY_P}

src_install() {
	dodoc CHANGELOG INSTALL README.md UPGRADING

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess

	fowners apache.apache "${MY_HTDOCSDIR}"/logs
	fowners apache.apache "${MY_HTDOCSDIR}"/temp

	insinto /var/log/roundcube
	fowners apache.apache /var/log/roundcube

	insinto /var/lib/roundcube
	fowners apache.apache /var/lib/roundcube
}

pkg_postinst() {
	if [ ! -e "${ROOT}""${MY_HTDOCSDIR}"/config/config.inc.php ]; then
		cp "${FILESDIR}"/bubba.conf "${ROOT}""${MY_HTDOCSDIR}"/config/config.inc.php
		elog "copy bubba default config"
		des_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9+*%&?!$-_=' | fold -w 24 | head -n 1)
		elog "generated new secret key: ${des_key}"
		sed -i "/des_key/d" "${ROOT}""${MY_HTDOCSDIR}"/config/config.inc.php
		sed -i "/^?>/d" "${ROOT}""${MY_HTDOCSDIR}"/config/config.inc.php
		echo "\$config['des_key'] = '${des_key}';" >> "${ROOT}""${MY_HTDOCSDIR}"/config/config.inc.php
		echo "?>" >> "${ROOT}""${MY_HTDOCSDIR}"/config/config.inc.php
	fi

        ewarn
        ewarn "When upgrading from <= 0.9, note that the old configuration files"
        ewarn "named main.inc.php and db.inc.php are deprecated and should be"
        ewarn "replaced with one single config.inc.php file."
        ewarn
        ewarn "Run the ./bin/update.sh script to convert those"
        ewarn "or manually merge the files."
        ewarn
        ewarn "The new config.inc.php should only contain options that"
        ewarn "differ from the ones listed in defaults.inc.php."
        ewarn
}

