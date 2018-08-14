# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils perl-module systemd

MY_PV=${PV/_*/}
DESCRIPTION="Excito B3 administrative scripts"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://b3.update.excito.org/pool/main/b/${PN}/${PN}_${MY_PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+apache2 nginx systemd"

REQUIRED_USE="^^ ( apache2 nginx )"

DEPEND="
	dev-lang/perl:=
"

RDEPEND="${DEPEND}
	app-admin/bubba-diskmanager
	app-admin/bubba-networkmanager
	app-arch/zip
	dev-perl/Config-Simple
	dev-perl/Config-Tiny
	dev-perl/Crypt-PasswdMD5
	dev-perl/Crypt-SSLeay
	dev-perl/Expect
	dev-perl/File-Slurp
	dev-perl/IPC-Run
	dev-perl/IPC-Run3
	>=dev-perl/JSON-2.900.0
	>=dev-perl/JSON-XS-3.10.0
	dev-perl/List-MoreUtils
	dev-perl/Try-Tiny
	dev-perl/XML-Parser
	dev-perl/XML-Simple
	dev-python/pycups
	dev-python/pyyaml
	>=sys-apps/bubba-info-1.4[php,perl]
	>=sys-libs/timezone-data-2015e
	systemd? ( sys-apps/systemd )
"

S=${WORKDIR}/${PN}


src_prepare() {
	epatch ${FILESDIR}/gentoo.patch
	epatch ${FILESDIR}/bubba-firewall.patch
	epatch ${FILESDIR}/change-tz.patch
	if use systemd; then
		cp -a ${FILESDIR}/bubba-firewall.initd ${S}/bubba-firewall.sh
		epatch ${FILESDIR}/systemd.patch
		touch -r ${FILESDIR}/bubba-firewall.initd ${S}/bubba-firewall.sh
	fi

	# inconsistent service names
	if use systemd; then
		sed -i "s/cupsd/cups/" web-admin/lib/Bubba.pm
		sed -i "s/cups\.conf/cupsd.conf/" web-admin/lib/Bubba.pm
	else
		sed -i "s/forked-daapd/daapd/" web-admin/lib/Bubba.pm
		sed -i "s/forked-daapd/daapd/" web-admin/bin/diskdaemon.pl
		sed -i "s/forked-daapd/daapd/" web-admin/bin/adminfunctions.php
	fi
}


src_configure() {
	perl Makefile.PL NAME="Bubba"
}


src_compile() {
	make DESTDIR=${ED}
}


src_install() {
	make DESTDIR=${ED} install

	exeinto /opt/bubba/bin
	doexe airprint-generate new_printer_init.sh cups-list-printers smbd-reload ${FILESDIR}/identify_box bubba-run-backupjobs ${FILESDIR}/dpkg-query
	dosym /opt/bubba/bin/dpkg-query /usr/bin/dpkg-query
 
	insinto /var/lib/bubba
	doins iptables.xslt hosts.in personal-setting-files.txt

	if use systemd; then
		systemd_dounit "${FILESDIR}/bubba-firewall.service"
		exeinto /opt/bubba/sbin
		doexe bubba-firewall.sh
	else
		newinitd ${FILESDIR}/bubba-firewall.initd  bubba-firewall
	fi
	newconfd ${FILESDIR}/bubba-firewall.confd  bubba-firewall

	dodoc "${S}/debian/copyright" ${FILESDIR}/Changelog
	newdoc "${S}/debian/changelog" changelog.debian
	insinto /usr/share/doc/${PF}/examples
	docompress -x /usr/share/doc/${PF}/examples
	doins services/*
	doins ${FILESDIR}/firewall.conf sysctl.conf auth_template.xml

	insinto /etc/cron.d
	newins ${FILESDIR}/excito-backup.crond excito-backup
	newins ${FILESDIR}/bubba-notify.crond bubba-notify

	insinto /var/spool/bubba-notify
	insinto /etc/bubba-notify/
	doins bubba-notify.conf
	insinto /etc/bubba-notify/available
	insinto /etc/bubba-notify/enabled
}


pkg_postinst() {
	if ! getent passwd admin >/dev/null; then
		elog "Adding administrator user \"admin\"";
		/usr/sbin/useradd -m -c "Administrator" -s "/bin/bash" -U -G users,lpadmin -p `perl -MCrypt::PasswdMD5 -e 'print unix_md5_crypt("admin")'` admin;
	fi

	if [ ! -f /home/admin/.bubbacfg ]; then
		echo "default_lang=en" > /home/admin/.bubbacfg
		echo "default_locale=en_US" >> /home/admin/.bubbacfg
		echo "network_profile=router" >> /home/admin/.bubbacfg
		echo "run_wizard=no" >> /home/admin/.bubbacfg
		use apache2 && chown root.apache /home/admin/.bubbacfg
		use nginx && chown root.nginx /home/admin/.bubbacfg
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

		iptables-save -t filter | grep "^\-\|^:" | cut -d[ -f1 > /tmp/${PF}_act_filter
		iptables-save -t nat | grep "^\-\|^:" | cut -d[ -f1 > /tmp/${PF}_act_nat

		FS=$(grep -n "*filter" /etc/bubba/firewall.conf | cut -d: -f1)
		NS=$(grep -n "*nat" /etc/bubba/firewall.conf | cut -d: -f1)
		grep -n "COMMIT" /etc/bubba/firewall.conf | cut -d: -f1 | while read row; do
			if [ ${row} -gt ${FS} ]; then
				FS=$((FS+1))
				row=$((row-1))
				sed -n ${FS},${row}p /etc/bubba/firewall.conf | cut -d[ -f1 > /tmp/${PF}_sav_filter
				FS=1000000
			fi

			if [ ${row} -gt ${NS} ]; then
				NS=$((NS+1))
				row=$((row-1))
				sed -n ${NS},${row}p /etc/bubba/firewall.conf | cut -d[ -f1 > /tmp/${PF}_sav_nat
				NS=1000000
			fi
		done

		MATCH_FLT=$(diff -q /tmp/${PF}_sav_filter /tmp/${PF}_act_filter &>/dev/null && echo yes || echo no)
		MATCH_NAT=$(diff -q /tmp/${PF}_sav_nat /tmp/${PF}_act_nat &>/dev/null && echo yes || echo no)

		if [ "${MATCH_FLT}${MATCH_NAT}" != "yesyes" ]; then
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
				ewarn "replaced empty /etc/bubba/firewall.conf with default firewall config"
				cp /usr/share/doc/${PF}/examples/firewall.conf /etc/bubba/firewall.conf
			else
				if ! grep -q "^:Bubba_IN" /tmp/${PF}_act_filter ; then
					einfo "create new chain Bubba_IN"
					/sbin/iptables -N Bubba_IN
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_IN" /tmp/${PF}_act_filter ; then
					einfo "add chain Bubba_IN as a target at the end of your current INPUT rules"
					/sbin/iptables -A INPUT -j Bubba_IN
				fi

				if ! grep -q "^:Bubba_FWD" /tmp/${PF}_act_filter ; then
					einfo "create new chain Bubba_FWD"
					/sbin/iptables -N Bubba_FWD
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_FWD" /tmp/${PF}_act_filter ; then
					einfo "add chain Bubba_FWD as a target at the end of your current FORWARD rules"
					/sbin/iptables -A FORWARD -j Bubba_FWD
				fi

				if ! grep -q "^:Bubba_SNAT" /tmp/${PF}_act_nat ; then
					einfo "create new chain Bubba_SNAT"
					/sbin/iptables -t nat -N Bubba_SNAT
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_SNAT" /tmp/${PF}_act_nat ; then
					einfo "add chain Bubba_SNAT as a target at the start of your current POSTROUTING rules"
					/sbin/iptables -t nat -I POSTROUTING 1 -j Bubba_SNAT
				fi

				if ! grep -q "^:Bubba_DNAT" /tmp/${PF}_act_nat ; then
					einfo "create new chain Bubba_DNAT"
					/sbin/iptables -t nat -N Bubba_DNAT
				fi
				if ! grep -qE ".*[^#].*\-j\s+Bubba_DNAT" /tmp/${PF}_act_nat ; then
					einfo "add chain Bubba_DNAT as a target at the start of your current PREROUTING rules"
					/sbin/iptables -t nat -I PREROUTING 1 -j Bubba_DNAT
				fi

				/sbin/iptables-save > /etc/bubba/firewall.conf
			fi
		fi

		if [ -r /tmp/${PF}-firewall.temp ]; then
			ewarn ""
			ewarn "Restoring original firewall status"
			/sbin/iptables-restore < /tmp/${PF}-firewall.temp
		fi

		rm -f /tmp/${PF}*
	fi


	if [ ! -e /etc/bubba/firewall.conf ]; then
		if iptables-save | grep -q "^-A "; then
			ewarn "You appear to be running another firewall already"
			ewarn "Please save your current rules if you need them,"
			ewarn "prior to starting bubba-firewall"
		fi
		einfo "Installing default firewall config"
		cp /usr/share/doc/${PF}/examples/firewall.conf /etc/bubba/firewall.conf
	fi

	# At present, the forked-daapd install does not provide a systemd service file, so
	# we cannot control the service. If /etc/forked-daapd.conf exists, either through
	# forked-daapd installer or our bubba-install we provide our own service file.
	if use systemd; then
		if [ -e /etc/forked-daapd.conf ] && [ ! -e /usr/lib/systemd/system/forked-daapd.service ]; then
			cp ${FILESDIR}/forked-daapd.service /usr/lib/systemd/system/
		fi
	fi
}

