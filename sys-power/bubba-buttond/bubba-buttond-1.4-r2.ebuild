# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

inherit eutils

DESCRIPTION="Excito B3 power control"
HOMEPAGE="http://www.excito.com/"
SRC_URI="http://update.mybubba.org/pool/main/b/${PN}/${PN}_${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~arm"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}/buttond


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
	dodir /sbin
	cp -a "${S}/buttond"   ${ED}/sbin
	cp -a "${S}/write-magic"   ${ED}/sbin
	create_runscript
	dodoc "${S}/debian/copyright"

	elog "To intercept signals from the B3 power button, you should add"
	elog "bubba-buttond to your default runlevel with the following"
	elog "command:"
	elog ""
	elog "\trc-update add bubba-buttond default"
	elog ""
	elog "To shutdown the B3 manually use this command:"
	elog ""
	elog "\twrite-magic 0xdeadbeef && reboot"
	elog ""
}
