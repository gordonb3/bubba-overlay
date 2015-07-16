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
        patch -p1 < ${FILESDIR}/${PN}-${MY_PV}.patch
	NAME=${PN} && export NAME
	perl Makefile.PL
	sed -i "s/= \$.PREFIX.\/lib\/web-admin/= \/opt\/bubba\/bin/" Makefile
}


src_compile() {
	make DESTDIR=${ED}
}


src_install() {
	make DESTDIR=${ED} install

	exeinto /opt/bubba/bin
	doexe airprint-generate new_printer_init.sh cups-list-printers smbd-reload identify_box bubba-run-backupjobs ${FILESDIR}/dpkg-query
	dosym /opt/bubba/bin/dpkg-query /usr/bin/dpkg-query
	insinto /opt/bubba/lib
	doins iptables.xslt
 
        insinto /var/lib/bubba
	doins iptables.xslt hosts.in

	newinitd ${FILESDIR}/bubba-firewall.initd  bubba-firewall
	newconfd ${FILESDIR}/bubba-firewall.confd  bubba-firewall

	dodoc "${S}/debian/copyright" "${S}/debian/changelog"
        insinto /usr/share/doc/${PF}/examples
        docompress -x /usr/share/doc/${PF}/examples
	doins services/*
	doins ${FILESDIR}/firewall.conf sysctl.conf auth_template.xml
}


pkg_postinst() {

	if ! getent passwd admin >/dev/null; then
		elog "Adding administrator user \"admin\"";
		/usr/sbin/useradd -m -c "Administrator" -s "/bin/bash" -U -G users,lpadmin -p `perl -MCrypt::PasswdMD5 -e 'print unix_md5_crypt("admin")'` admin;
		if [ ! -f /home/admin/.bubbacfg ]; then
			echo "default_lang=en\ndefault_locale=en_US" > /home/admin/.bubbacfg
			echo "network_profile = router" >> /home/admin/.bubbacfg
			echo "run_wizard = no" >> /home/admin/.bubbacfg
			use apache2 && chown root.apache /home/admin/.bubbacfg
			use nginx && chown root.nginx /home/admin/.bubbacfg
		fi
	fi


	if [ ! -e /etc/bubba/auth.xml ]; then
		elog "Installing default auth config"
		cp /usr/share/doc/${PF}/examples/auth_template.xml /etc/bubba/auth.xml
	fi


	if [ -r /etc/bubba/firewall.conf ]; then
		if ! /sbin/iptables-save | grep -q "^-A "; then
			ewarn "/etc/bubba/firewall.conf exists but you appear to have no current active firewall"
			ewarn "temporary enabling the rules from /etc/bubba/firewall.conf to run further checks"
			/sbin/iptables-save > /tmp/${PF}-firewall.temp
			/sbin/iptables-restore < /etc/bubba/firewall.conf
		fi

		if /sbin/iptables-save| diff -u /etc/bubba/firewall.conf /dev/stdin | grep -vqE "^.#|^.:|^@@|^---|\+\+\+|^ "; then
			ewarn "/etc/bubba/firewall.conf exists but does not contain your current running firewall state"
			ewarn "skipping any further checks"
			ewarn ""
			ewarn "If you like to be able to use the Bubba web interface to manage your firewall,"
			ewarn "then please make sure to save your current state to /etc/bubba/firewall.conf"
			ewarn "and that the following rules are included:"
			ewarn ""
			ewarn "iptables -N Bubba_IN"
			ewarn "iptables -A INPUT -j Bubba_IN"
			ewarn "iptables -N Bubba_FWD"
			ewarn "iptables -A FORWARD -j Bubba_FWD"
			ewarn "iptables -t nat -N Bubba_DNAT"
			ewarn "iptables -t nat -A PREROUTING -j Bubba_DNAT"
			ewarn "iptables -t nat -N Bubba_SNAT"
			ewarn "iptables -t nat -A POSTROUTING -j Bubba_SNAT"

		else
			if ! grep -q "^-A " /etc/bubba/firewall.conf; then
				ewarn "/etc/bubba/firewall.conf exists but does not contain any rules"
				ewarn "Replacing /etc/bubba/firewall.conf with default firewall config"
				cp /usr/share/doc/${PF}/examples/firewall.conf /etc/bubba/firewall.conf
			else
				if ! grep -qE ".*[^#].*\-j\s+Bubba_IN" /etc/bubba/firewall.conf ; then
					ewarn "Your firewall conf is missing a reference to chain Bubba_IN"
					ewarn "I'll add this for you at the end of your current INPUT rules.
					/sbin/iptables -N Bubba_IN
					/sbin/iptables -A INPUT -j Bubba_IN
					/sbin/iptables-save > /etc/bubba/firewall.conf
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_FWD" /etc/bubba/firewall.conf ; then
					ewarn "Your firewall conf is missing a reference to chain Bubba_IN"
					ewarn "I'll add this for you at the end of your current FORWARD rules.
					/sbin/iptables -N Bubba_FWD
					/sbin/iptables -A FORWARD -j Bubba_FWD
					/sbin/iptables-save > /etc/bubba/firewall.conf
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_SNAT" /etc/bubba/firewall.conf ; then
					ewarn "Your firewall conf is missing a reference to chain Bubba_IN"
					ewarn "I'll add this for you at the startt of your current POSTROUTING rules.
					/sbin/iptables -t nat -N Bubba_SNAT
					/sbin/iptables -I POSTROUTING -j Bubba_SNAT
					/sbin/iptables-save > /etc/bubba/firewall.conf
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_DNAT" /etc/bubba/firewall.conf ; then
					ewarn "Your firewall conf is missing a reference to chain Bubba_IN"
					ewarn "I'll add this for you at the start of your current PREROUTING rules."
					/sbin/iptables -t nat -N Bubba_DNAT
					/sbin/iptables -I PREROUTING -j Bubba_DNAT
					/sbin/iptables-save > /etc/bubba/firewall.conf
				fi

			fi
		fi

		if [ -r /tmp/${PF}-firewall.temp ]; then
			ewarn "Restoring original firewall status"
			/sbin/iptables-restore < /tmp/${PF}-firewall.temp
			rm /tmp/${PF}-firewall.temp
		fi

	fi


	if [ ! -e /etc/bubba/firewall.conf ]; then
		if iptables-save | grep -q "^-A "; then
			ewarn "You appear to be running another firewall already"
			ewarn "Please save your current rules if you need them,"
			ewarn "prior to starting bubba-firewall"
		fi
		elog "Installing default firewall config"
		cp /usr/share/doc/${PF}/examples/firewall.conf /etc/bubba/firewall.conf
	fi

}

