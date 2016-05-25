# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
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
	if [ "$(cat /var/db/pkg/sys-apps/sysvinit-*/repository)" == "bubba" ]; then
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
APPROOT=/opt/bubba/sbin
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
	exeinto /opt/bubba/sbin
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
	rc-status default | grep -q bubba-buttond || rc-config add bubba-buttond default
	if $(rc-service bubba-buttond status &>/dev/null); then
		rc-service bubba-buttond restart
	else
		rc-service bubba-buttond start
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
	rc-service bubba-buttond status &>/dev/null && rc-service bubba-buttond stop
	rc-status default | grep -q bubba-buttond && rc-config delete bubba-buttond default
}

