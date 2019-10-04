# Copyright 2018 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils perl-module systemd

DESCRIPTION="Excito B3 administrative scripts"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://b3.update.excito.org/pool/main/b/${PN}/${PN}_2.6.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="+apache2 nginx systemd +iptables nftables"

REQUIRED_USE="^^ ( apache2 nginx )
	?? ( iptables nftables )
"

DEPEND="
	dev-lang/perl:=
	iptables? ( net-firewall/iptables )
	nftables? ( net-firewall/nftables )
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
	epatch ${FILESDIR}/change_tz.patch
	epatch ${FILESDIR}/use_fixed_paths.patch
	if use systemd; then
		if use nftables; then
			# this will cause a fuzz with the next patch, but it will pass
			cp -a ${FILESDIR}/bubba-nft.initd ${S}/bubba-firewall.sh
		else
			cp -a ${FILESDIR}/bubba-firewall.initd ${S}/bubba-firewall.sh
		fi
		epatch ${FILESDIR}/systemd.patch
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

	if ! use iptables; then
		sed -i "/firewall.pl/d" web-admin/Makefile.PL
	fi

	# systemd binaries have moved from /usr/bin to /bin with later versions
	if use systemd; then
		SYSTEMCTL=$(equery f systemd | grep "bin/systemctl$")
		sed -e "s#/usr/bin/systemctl#${SYSTEMCTL}#g" -i web-admin/bin/diskdaemon.pl
		sed -e "s#/usr/bin/systemctl#${SYSTEMCTL}#g" -i web-admin/bin/adminfunctions.php
		sed -e "s#/usr/bin/systemctl#${SYSTEMCTL}#g" -i web-admin/lib/Bubba.pm
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
	if use nftables; then
		newexe "${FILESDIR}/nftfirewall.pl" firewall.pl
	fi
 
	insinto /var/lib/bubba
	if use iptables; then
		doins iptables.xslt
	fi
	doins hosts.in personal-setting-files.txt


	#firewall support
	if use iptables; then
		if use systemd; then
			systemd_dounit "${FILESDIR}/bubba-firewall.service"
			exeinto /opt/bubba/sbin
			doexe bubba-firewall.sh
		else
			newinitd ${FILESDIR}/bubba-firewall.initd  bubba-firewall
		fi
		newconfd ${FILESDIR}/bubba-firewall.confd  bubba-firewall
	fi
	if use nftables; then
		if use systemd; then
			systemd_dounit "${FILESDIR}/bubba-firewall.service"
			exeinto /opt/bubba/sbin
			doexe bubba-firewall.sh
		else
			newinitd ${FILESDIR}/bubba-nft.initd  bubba-firewall
		fi
		newconfd ${FILESDIR}/bubba-nft.confd  bubba-firewall
	fi

	# documentation
	dodoc "${S}/debian/copyright" ${FILESDIR}/Changelog
	newdoc "${S}/debian/changelog" changelog.debian
	insinto /usr/share/doc/${PF}/examples
	docompress -x /usr/share/doc/${PF}/examples
	doins services/*
	if use iptables; then
		doins ${FILESDIR}/firewall.conf
	fi
	if use nftables; then
		doins ${FILESDIR}/firewall.nft
	fi
	doins  sysctl.conf auth_template.xml

	# cron targets
	insinto /etc/cron.d
	newins ${FILESDIR}/excito-backup.crond excito-backup
	newins ${FILESDIR}/bubba-notify.crond bubba-notify

	keepdir /var/spool/bubba-notify
	insinto /etc/bubba-notify/
	doins bubba-notify.conf
	keepdir /etc/bubba-notify/available
	keepdir /etc/bubba-notify/enabled
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


	if use iptables; then
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
	fi

	if use nftables; then
		ewarn ""
		ewarn "If you like to be able to use the Bubba web interface to manage your firewall,"
		ewarn "then please make sure to save your current state to /etc/bubba/firewall.nft"
		ewarn "and that the following rules are included:"
		ewarn ""
		ewarn "nftables add chain ip filter Bubba_IN"
		ewarn "nftables add rule ip filter INPUT jump Bubba_IN"
		ewarn "nftables add chain ip filter Bubba_FWD"
		ewarn "nftables add rule ip filter FORWARD jump Bubba_FWD"
		ewarn "nftables add chain ip nat Bubba_DNAT"
		ewarn "nftables add rule ip nat PREROUTING jump Bubba_DNAT"
		ewarn "nftables add chain ip nat Bubba_SNAT"
		ewarn "nftables add rule ip nat POSTROUTING jump Bubba_SNAT"
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

