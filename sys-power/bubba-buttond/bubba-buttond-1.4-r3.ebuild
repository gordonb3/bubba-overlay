# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Excito B3 power control"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.excito.org/pool/main/b/${PN}/${PN}_${PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

DEPEND=""

RDEPEND="${DEPEND}"


S=${WORKDIR}/buttond

pkg_setup() {
	ebegin "checking for write-magic enabled sysvinit"
	if [ `equery -q l sys-apps/sysvinit` == "sys-apps/sysvinit-9999" ]; then
		eend 0
		ENABLE_COMPAT="no"
	else
		eend 1 "   incorrect version number -> reverting to backward compatibility"
		ENABLE_COMPAT="yes"
	fi

}


src_compile() {
	make
}


create_runscript() {
	dodir /etc/init.d
	cat > ${ED}/etc/init.d/bubba-buttond <<EOF
#!/sbin/runscript

NAME=bubba-buttond
APPROOT=/sbin
DAEMON=buttond
PIDFILE=/var/run/\${NAME}.pid


start() {
        ebegin "Starting \${NAME}"
		start-stop-daemon --start --quiet --make-pidfile --pidfile \${PIDFILE} --background --exec \${APPROOT}/\${DAEMON}
        eend \$?
}

stop() {
        ebegin "Stopping \${NAME}"
	        start-stop-daemon --stop --quiet --pidfile \${PIDFILE}
        eend \$?
}
EOF
	chmod +x ${ED}/etc/init.d/bubba-buttond
}

src_install() {
	exeinto /sbin
	doexe buttond

	exeinto /opt/bubba/bin
	doexe write-magic

	if [ ${ENABLE_COMPAT} == "yes" ];then
		dosym /opt/bubba/bin/write-magic /sbin/write-magic
	fi

	create_runscript
	dodoc "${S}/debian/copyright"
}

pkg_postinst() {
	elog "To intercept signals from the B3 power button, you should add"
	elog "bubba-buttond to your default runlevel with the following"
	elog "command:"
	elog ""
	elog "\trc-update add bubba-buttond default"
	elog ""
	if [ ${ENABLE_COMPAT} == "yes" ];then
		elog "To shutdown the B3 manually use this command:"
		elog ""
		elog "\twrite-magic 0xdeadbeef && reboot"
	else
		elog "A copy of the old write-magic shutdown helper application"
		elog "has been placed in /opt/bubba/bin for your convenience"
	fi
	elog ""

}
