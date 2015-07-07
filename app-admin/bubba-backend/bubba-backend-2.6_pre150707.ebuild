# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils perl-module

MY_PV=${PV/_*/}
DESCRIPTION="Excito B3 administrative scripts"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/b/${PN}/${PN}_${MY_PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE="+apache2 nginx"

REQUIRED_USE="^^ ( apache2 nginx )"

DEPEND=""

RDEPEND="${DEPEND}
	app-arch/zip
	dev-perl/JSON
	dev-perl/JSON-XS
	dev-perl/File-Slurp
	dev-perl/Crypt-PasswdMD5
	dev-perl/XML-Parser
	dev-perl/XML-Simple
	dev-perl/IPC-Run
	dev-perl/IPC-Run3
	dev-perl/Expect
	dev-perl/Config-Tiny
	dev-perl/Try-Tiny
	dev-perl/Crypt-SSLeay
	dev-perl/Config-Simple
	dev-perl/List-MoreUtils
	sys-libs/timezone-data[right_timezone]
"

S=${WORKDIR}/${PN}


src_prepare() {
        patch -p1 < ${FILESDIR}/${P}.patch
	NAME=${PN} && export NAME
	perl Makefile.PL
	sed -i "s/= \$.PREFIX.\/lib\/web-admin/= \/opt\/bubba\/bin/" Makefile
}


src_compile() {
	make DESTDIR=${D}
}


src_install() {
	make DESTDIR=${D} install

	exeinto /opt/bubba/bin
	doexe airprint-generate new_printer_init.sh cups-list-printers smbd-reload identify_box bubba-run-backupjobs ${FILESDIR}/dpkg-query
	dosym /opt/bubba/bin/dpkg-query /usr/bin/dpkg-query
	insinto /opt/bubba/lib
	doins iptables.xslt
 
	dodoc "${S}/debian/copyright" "${S}/debian/changelog"
        insinto /usr/share/doc/${PF}/sample
        docompress -x /usr/share/doc/${PF}/sample
	doins services/*
	doins firewall.conf sysctl.conf auth_template.xml hosts.in

}


pkg_postinst() {

	if ! getent passwd admin >/dev/null; then
		echo "Adding administrator user \"admin\"";
		/usr/sbin/useradd -m -c "Administrator" -s "/bin/bash" -U -G users,lpadmin -p `perl -MCrypt::PasswdMD5 -e 'print unix_md5_crypt("admin")'` admin;
		if [ ! -f /home/admin/.bubbacfg ]; then
			echo "run_wizard = yes" > /home/admin/.bubbacfg
			echo "network_profile = auto" >> /home/admin/.bubbacfg
			use apache2 && chown root.apache /home/admin/.bubbacfg
			use nginx && chown root.nginx /home/admin/.bubbacfg
		fi
	fi

	if [ ! -e /etc/bubba/firewall.conf ]; then
		echo "Installing default firewall config"
		cp /usr/share/doc/${PF}/sample/firewall.conf /etc/bubba/firewall.conf
	fi

	if [ ! -e /etc/bubba/auth.xml ]; then
		echo "Installing default auth config"
		cp /usr/share/doc/${PF}/sample/auth_template.xml /etc/bubba/auth.xml
	fi
}



