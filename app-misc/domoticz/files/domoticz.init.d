#!/sbin/openrc-run

NAME=domoticz
DAEMON=$NAME
PIDFILE=/var/run/$NAME.pid
DOMOTICZ_USER=root

depend() {
        need net
}

checkconfig() {
	if ! (set -u; : $WWWROOT) 2>/dev/null; then
		eerror "Please edit /etc/conf.d/${NAME}"
		eerror "\${WWWROOT} not defined!"
		return 1
	fi

	if ! (set -u; : $LOGFILE) 2>/dev/null; then
		eerror "Please edit /etc/conf.d/${NAME}"
		eerror "\${LOGFILE} not defined!"
		return 1
	fi

	if ! (set -u; : $DBASE) 2>/dev/null; then
		eerror "Please edit /etc/conf.d/${NAME}"
		eerror "\${DBASE} not defined!"
		return 1
	fi

	if ! (set -u; : $APPROOT) 2>/dev/null; then
		eerror "Please edit /etc/conf.d/${NAME}"
		eerror "\${APPROOT} not defined!"
		return 1
	fi

	return 0
}

start() {
	checkconfig
        ebegin "Starting Domoticz"
		start-stop-daemon --start --quiet --user ${DOMOTICZ_USER} --make-pidfile --pidfile ${PIDFILE} --background --exec ${APPROOT}/${DAEMON} --  -dbase ${DBASE} -wwwroot ${WWWROOT} -log ${LOGFILE} -approot ${APPROOT} ${EXTRAPARMS}
        eend $?
}

stop() {
        ebegin "Stopping Domoticz"
        start-stop-daemon --stop --quiet --pidfile ${PIDFILE}
        eend $?
}
