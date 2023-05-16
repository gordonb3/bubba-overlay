# Copyright 2015-2022 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit systemd toolchain-funcs

DESCRIPTION="Excito B3 power control"
HOMEPAGE="http://www.excito.com/"
COMMIT="8e6b241"
SRC_URI="https://github.com/excito/${PN}/archive/${COMMIT}.tar.gz -> ${PN}-${PVR}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE="systemd"

DEPEND=""

RDEPEND="systemd? ( sys-apps/systemd )"


pkg_setup() {
	ebegin "checking for write-magic enabled sysvinit"
	if grep -qoa "wrote B3 halt magic values" /sbin/shutdown ; then
		eend 0
		ENABLE_COMPAT="no"
	else
		eend 1 "   incorrect version number -> reverting to backward compatibility"
		ENABLE_COMPAT="yes"
	fi

}


src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-* ${S}
}

src_compile() {
	emake CC=$(tc-getCC)
}


src_install() {
	exeinto /opt/bubba/sbin
	doexe buttond

	exeinto /opt/bubba/bin
	doexe write-magic

	if [ ${ENABLE_COMPAT} == "yes" ];then
		dosym /opt/bubba/bin/write-magic /sbin/write-magic
	fi

	if use systemd; then
		systemd_dounit ${FILESDIR}/bubba-buttond.service
	else
		newinitd ${FILESDIR}/bubba-buttond.initd bubba-buttond
	fi
	dodoc "${S}/debian/copyright"
}

pkg_postinst() {
	if use systemd; then
		systemctl daemon-reload
		systemctl is-enabled bubba-buttond >/dev/null || {
			elog "enable bubba-buttond service"
			systemctl enable bubba-buttond >/dev/null
		}
		systemctl is-active bubba-buttond >/dev/null && systemctl stop bubba-buttond >/dev/null
		elog "auto starting bubba-buttond service"
		systemctl start bubba-buttond
		sed -i -e '$a\' /etc/systemd/logind.conf
		echo "HandlePowerKey=ignore" >> /etc/systemd/logind.conf
		systemctl restart systemd-logind
	else
		rc-status default | grep -q bubba-buttond || rc-config add bubba-buttond default
		if $(rc-service bubba-buttond status &>/dev/null); then
			rc-service bubba-buttond restart
		else
			rc-service bubba-buttond start
		fi
	fi

	if [ ${ENABLE_COMPAT} == "yes" ];then
		elog "To manually shutdown the B3 manually use this command:"
		elog ""
		elog "\twrite-magic 0xdeadbeef && reboot"
	fi
	elog ""

}

pkg_prerm()
{
	which systemctl &>/dev/null && {
		systemctl daemon-reload
		systemctl is-active bubba-buttond >/dev/null && systemctl stop bubba-buttond >/dev/null
		systemctl is-enabled bubba-buttond >/dev/null && systemctl disable bubba-buttond >/dev/null

		sed -i "/^HandlePowerKey=ignore/d" /etc/systemd/logind.conf
		systemctl restart systemd-logind
	}
	rc-service bubba-buttond status &>/dev/null && rc-service bubba-buttond stop
	rc-status default | grep -q bubba-buttond && rc-config delete bubba-buttond default
}

