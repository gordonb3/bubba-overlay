# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

ORG_PN=${PN/bubba-//}
MY_PN=${PN/bubba-//}mail
MY_P=${MY_PN}-${PV/_/-}
MY_HTDOCSDIR="/opt/roundcube/htdocs"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="https://roundcube.net"
SRC_URI="https://github.com/${ORG_PN}/${MY_PN}/releases/download/${PV}/${MY_P}-complete.tar.gz"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="amd64 arm ppc ppc64 ~sparc x86"

IUSE="enigma ldap managesieve -mysql -postgres +sqlite ssl spell"
REQUIRED_USE="|| ( mysql postgres sqlite )"

SLOT="0"
DEPEND="|| ( virtual/httpd-cgi virtual/httpd-fastcgi )"

# :TODO: Support "endriod/qrcode: ~1.6.5" dep (ebuild needed)
RDEPEND="
	${DEPEND}
	>=dev-lang/php-8.0.0[filter,gd,iconv,ldap?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml]
	virtual/httpd-php
	enigma? (
		>=dev-php/PEAR-Crypt_GPG-1.6.0
		app-crypt/gnupg
	)
	mysql? (
		|| (
			dev-lang/php[mysql]
			dev-lang/php[mysqli]
		)
	)
	spell? ( dev-lang/php[curl,spell] )
"

S=${WORKDIR}/${MY_P}

src_install() {
	dodoc CHANGELOG.md INSTALL README.md UPGRADING SECURITY.md

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess

	fowners apache:apache "${MY_HTDOCSDIR}"/logs
	fowners apache:apache "${MY_HTDOCSDIR}"/temp

	insinto /var/log/roundcube
	fowners apache:apache /var/log/roundcube

	insinto /var/lib/roundcube
	fowners apache:apache /var/lib/roundcube
}

pkg_postinst() {
	if [[ -n ${REPLACING_VERSIONS} ]]; then
		elog "You can review the post-upgrade instructions at:"
		elog "${EROOT}/opt/roundcube/htdocs/postupgrade-en.txt"
	fi
}
