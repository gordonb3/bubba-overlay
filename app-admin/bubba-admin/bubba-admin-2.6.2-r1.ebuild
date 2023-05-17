# Copyright 2021 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit cmake systemd tmpfiles

DESCRIPTION="Excito B3 administration tools and GUI"
HOMEPAGE="http://www.excito.com/"
SRC_URI="https://github.com/gordonb3/${PN}/archive/${PV}.tar.gz -> ${PN}-${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE="+apache2 nginx systemd +iptables nftables +wifi debug"

REQUIRED_USE="^^ ( apache2 nginx )
	?? ( iptables nftables )
"

PATCHES=(
	"${FILESDIR}/libeutils-0.7.39.patch"
)


COMMON_DEPEND="
	dev-lang/perl:=
	dev-libs/glib
	dev-libs/libnl
	dev-libs/popt
	dev-tcltk/expect
	sys-block/parted
	sys-fs/lvm2
	iptables? ( net-firewall/iptables )
	nftables? ( net-firewall/nftables )
	systemd? (
	  sys-apps/systemd
	  net-misc/networkmanager[dhcpcd,-dhclient]
	)
"

BACKEND_DEPEND="
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
"

DISKMANAGER_DEPEND="
	sys-fs/mdadm
"

NETWORKMANAGER_DEPEND="
	net-misc/dhcpcd
	wifi? ( net-misc/bridge-utils
		net-wireless/hostapd
		net-wireless/iw
		net-wireless/wireless-tools )
"

GUI_DEPEND="
	app-admin/hddtemp
	>=dev-lang/php-8.0.0[fpm,sockets,xml,gd,pdo,imap]
	dev-php/PEAR-HTTP_Request2
	sys-apps/bubba-info[php]
	www-apps/codeigniter-bin
	apache2? (
		dev-lang/php[apache2]
		sys-apps/bubba-info[apache2]
		>=www-servers/apache-2.4.9[apache2_modules_proxy,apache2_modules_proxy_fcgi,apache2_modules_proxy_http,apache2_modules_rewrite]
	)
	nginx? ( www-servers/nginx[nginx_modules_http_proxy,nginx_modules_http_rewrite,nginx_modules_http_fastcgi,nginx_modules_http_access,nginx_modules_http_auth_basic,nginx_modules_http_referer] )
"

DEPEND="
	${COMMON_DEPEND}
	dev-util/cppunit
	dev-util/cmake
	sys-devel/libtool
	sys-devel/m4
	dev-perl/Locale-PO
	dev-perl/Getopt-Long-Descriptive
"

RDEPEND="
	${COMMON_DEPEND}
	${DISKMANAGER_DEPEND}
	${NETWORKMANAGER_DEPEND}
	${BACKEND_DEPEND}
	${GUI_DEPEND}
"

# cmake requires access to included `external` project sources
CMAKE_IN_SOURCE_BUILD=yes

src_prepare() {
	eapply_user

	# add gentoo logo to the web GUI
	eapply ${S}/contrib/gentoo/gentoo-logo.patch

	# inconsistent service names
	if use systemd; then
		# all instances of cupsd => cups ...
		sed -e "s/cupsd/cups/" -i bubba-backend/web-admin/lib/Bubba.pm -i contrib/systemd/systemctl.patch
		# ... except `cupsd.conf`
		sed -e "s/cups\.conf/cupsd.conf/" -i bubba-backend/web-admin/lib/Bubba.pm
	else
		sed -e "s/forked-daapd/daapd/" \
		    -i bubba-backend/web-admin/lib/Bubba.pm \
		    -i bubba-backend/web-admin/bin/diskdaemon.pl \
		    -i bubba-backend/web-admin/bin/adminfunctions.php
	fi

	if ! use iptables; then
		sed -e "/firewall.pl/d" -i bubba-backend/web-admin/Makefile.PL
	fi

	# systemd binaries location is inconsistent between versions
	if use systemd; then
		SYSTEMCTL=$(equery f systemd | grep "bin/systemctl$")
		sed -e "s#/usr/bin/systemctl#${SYSTEMCTL}#g" \
		    -i bubba-backend/web-admin/lib/Bubba.pm \
		    -i bubba-backend/web-admin/bin/adminfunctions.php \
		    -i bubba-backend/web-admin/bin/diskdaemon.pl
	fi

	# debug USE flag enables extra logging in web UI
	if use debug; then
		sed  -e "s/^\(define('ENVIRONMENT', '\).*\(');\)$/\1development\2/" -i bubba-frontend/admin/index.php
	fi
	
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_CXX_FLAGS_GENTOO="-O3 -DNDEBUG"
		-DWITH_SYSTEMD=$(usex systemd)
	)

	cmake_src_configure
}

bubba_admin_install_iptables_support() {
	insinto /var/lib/bubba
	doins bubba-backend/iptables.xslt

	newconfd ${S}/contrib/gentoo/bubba-firewall.confd bubba-firewall
	if use systemd; then
		systemd_dounit ${S}/contrib/systemd/bubba-firewall.service
		exeinto /opt/bubba/sbin
		doexe ${S}/contrib/systemd/bubba-firewall.sh
	else
		newinitd ${S}/contrib/gentoo/bubba-firewall.initd bubba-firewall
	fi

	insinto /usr/share/doc/${PF}/examples
	docompress -x /usr/share/doc/${PF}/examples
	doins ${FILESDIR}/firewall.conf
}

bubba_admin_install_netfilter_support() {
	exeinto /opt/bubba/bin
		doexe ${S}/contrib/netfilter/firewall.pl

	newconfd ${S}/contrib/netfilter/bubba-firewall.confd bubba-firewall
	if use systemd; then
		systemd_dounit ${S}/contrib/systemd/bubba-firewall.service
		exeinto /opt/bubba/sbin
		doexe ${S}/contrib/netfilter/bubba-firewall.sh
	else
		newinitd ${S}/contrib/netfilter/bubba-firewall.initd bubba-firewall
	fi

	insinto /usr/share/doc/${PF}/examples
	docompress -x /usr/share/doc/${PF}/examples
	doins ${FILESDIR}/firewall.nft
}

bubba_admin_install_GUI() {
	SYSTEM_TIMEZONE=$(cat /etc/timezone)
	PHP_CLI_INI_PATH=$(php -n --ini | grep -v "(none)" | awk '{print $NF}')
	PHP_APACHE_INI_PATH=$(echo ${PHP_CLI_INI_PATH} | sed "s/cli/apache2/")
	PHP_FPM_INI_PATH=$(echo ${PHP_CLI_INI_PATH} | sed "s/cli/fpm/")

	insinto ${PHP_FPM_INI_PATH}/ext
	newins bubba-frontend/php-cgi.conf bubba-admin.ini
	echo "date.timezone=\"${SYSTEM_TIMEZONE}\"" >> ${ED}/${PHP_FPM_INI_PATH}/ext/bubba-admin.ini
	dosym ${PHP_FPM_INI_PATH}/ext/bubba-admin.ini ${PHP_FPM_INI_PATH}/ext-active/bubba-admin.ini

	if use apache2; then
		insinto ${PHP_APACHE_INI_PATH}/ext
		newins bubba-frontend/php-apache.conf bubba-admin.ini
		echo "date.timezone=\"${SYSTEM_TIMEZONE}\"" >> ${ED}/${PHP_APACHE_INI_PATH}/ext/bubba-admin.ini
		dosym ${PHP_APACHE_INI_PATH}/ext/bubba-admin.ini ${PHP_APACHE_INI_PATH}/ext-active/bubba-admin.ini

		insinto /etc/apache2/vhosts.d
		newins contrib/gentoo/apache2.vhost bubba.conf
	fi
	if use nginx; then
		insinto /etc/nginx/vhosts.d
		newins contrib/gentoo/nginx.vhost bubba.conf
	fi

	insinto /etc/bubba
	newins contrib/gentoo/bubba-adminphp.conf adminphp.conf
	use nginx && sed "s/apache/nginx/" -i ${ED}/etc/bubba/adminphp.conf

	insinto /var/lib/bubba
	doins bubba-frontend/lite_php_browscap.ini

	keepdir /var/log/web-admin

	insinto /opt/bubba/web-admin/admin/views/default/_img
	doins contrib/gentoo/gentoo_logo.png

	if use systemd; then
		systemd_dounit contrib/systemd/bubba-adminphp.service
		if use nginx; then
			sed -e "s/apache/nginx/g" -i contrib/systemd/bubba-adminphp.tmpfiles
		fi
		newtmpfiles contrib/systemd/bubba-adminphp.tmpfiles bubba-adminphp.conf
	else
		newinitd contrib/gentoo/bubba-adminphp.initd bubba-adminphp
	fi
}

src_install() {
	cmake_src_install

#	exeinto /opt/bubba/bin
#	doexe bubba-backend/new_printer_init.sh

	dosym /opt/bubba/bin/dpkg-query /usr/bin/dpkg-query

	insinto /var/lib/bubba
	doins bubba-backend/hosts.in bubba-backend/personal-setting-files.txt

	# notify agent
	insinto /etc/bubba-notify/
	doins   bubba-backend/bubba-notify.conf
	keepdir /etc/bubba-notify/available
	keepdir /etc/bubba-notify/enabled
	keepdir /var/spool/bubba-notify

	# cron targets
	insinto /etc/cron.d
	newins ${FILESDIR}/excito-backup.crond excito-backup
	newins ${FILESDIR}/bubba-notify.crond bubba-notify

	# firewall support
	if use iptables; then
		bubba_admin_install_iptables_support
	fi
	if use nftables; then
		bubba_admin_install_netfilter_support
	fi

	# GUI
	bubba_admin_install_GUI

	# documentation
	dodoc ${S}/License.txt
	dodoc ${FILESDIR}/Changelog
	insinto /usr/share/doc/${PF}/examples
	docompress -x /usr/share/doc/${PF}/examples
	doins bubba-backend/sysctl.conf bubba-backend/auth_template.xml
	doins ${FILESDIR}/*.conf ${FILESDIR}/*.nft ${FILESDIR}/*.crond
	doins contrib/gentoo/apache2.vhost contrib/gentoo/nginx.vhost

	if use systemd; then
		insinto /etc/NetworkManager/conf.d
		echo -e "[main]\ndhcp=dhcpcd\n" > ${ED}/etc/NetworkManager/conf.d/dhcpcd.conf
	fi
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
		ewarn "Important note about firewall settings:"
		ewarn ""
		ewarn "If you like to be able to use the Bubba web interface to manage your firewall,"
		ewarn "then please make sure to save your current state to /etc/bubba/firewall.conf"
		ewarn "and that the following rules are included:"
		ewarn ""
		ewarn "  iptables -N Bubba_IN"
		ewarn "  iptables -A INPUT -j Bubba_IN"
		ewarn "  iptables -N Bubba_FWD"
		ewarn "  iptables -A FORWARD -j Bubba_FWD"
		ewarn "  iptables -t nat -N Bubba_DNAT"
		ewarn "  iptables -t nat -A PREROUTING -j Bubba_DNAT"
		ewarn "  iptables -t nat -N Bubba_SNAT"
		ewarn "  iptables -t nat -A POSTROUTING -j Bubba_SNAT"
		ewarn ""
	fi

	if use nftables; then
		ewarn "Important note about firewall settings:"
		ewarn ""
		ewarn "If you like to be able to use the Bubba web interface to manage your firewall,"
		ewarn "then please make sure to save your current state to /etc/bubba/firewall.nft"
		ewarn "and that the following rules are included:"
		ewarn ""
		ewarn "  nftables add chain ip filter Bubba_IN"
		ewarn "  nftables add rule ip filter INPUT jump Bubba_IN"
		ewarn "  nftables add chain ip filter Bubba_FWD"
		ewarn "  nftables add rule ip filter FORWARD jump Bubba_FWD"
		ewarn "  nftables add chain ip nat Bubba_DNAT"
		ewarn "  nftables add rule ip nat PREROUTING jump Bubba_DNAT"
		ewarn "  nftables add chain ip nat Bubba_SNAT"
		ewarn "  nftables add rule ip nat POSTROUTING jump Bubba_SNAT"
		ewarn ""
	fi

	# At present, the forked-daapd install does not provide a systemd service file, so
	# we cannot control the service. If /etc/forked-daapd.conf exists, either through
	# forked-daapd installer or our bubba-install we provide our own service file.
	if use systemd; then
		if [ -e /etc/forked-daapd.conf ] && [ ! -e /usr/lib/systemd/system/forked-daapd.service ]; then
			cp ${FILESDIR}/forked-daapd.service /usr/lib/systemd/system/
		fi
	fi

	if use nginx; then
		elog "Although this package was configured for nginx, it should also function"
		elog "with apache, provided apache was configured with the required use flags."
	else
		elog "Although this package was configured for apache, it should also function"
		elog "with nginx, provided nginx was configured with the required use flags."
	fi
	elog "Sample config files have been placed in /usr/share/doc/${PF}/examples"
	if use nginx; then
		elog ""
		elog "If you are manually switching to apache, please do not forget to enable"
		elog "the bubba-admin plugin for mod_php as well by copying php5-apache.conf"
		elog "from the examples folder to ${PHP_APACHE_INI_PATH}/ext/bubba-admin.ini"
		elog "and create a symlink to it from ${PHP_APACHE_INI_PATH}/ext-active"
	fi
}

