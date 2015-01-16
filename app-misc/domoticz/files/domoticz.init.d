#!/sbin/runscript

NAME=domoticz
DAEMON=$NAME
PIDFILE=/var/run/$NAME.pid
DOMOTICZ_USER=domoticz

depend() {
        need net
}

checkconfig() {
	if ! type "${WWWROOT}" >/dev/null 2>&1 ; then
		eerror "Please edit /etc/conf.d/domoticz"
		eerror "${WWWROOT} not defined!"
		return 1
	fi

	if ! type "${LOGFILE}" >/dev/null 2>&1 ; then
		eerror "Please edit /etc/conf.d/domoticz"
		eerror "${LOGFILE} not defined!"
		return 1
	fi

	if ! type "${DBASE}" >/dev/null 2>&1 ; then
		eerror "Please edit /etc/conf.d/domoticz"
		eerror "${DBASE} not defined!"
		return 1
	fi

	if ! type "${APPROOT}" >/dev/null 2>&1 ; then
		eerror "Please edit /etc/conf.d/domoticz"
		eerror "${APPROOT} not defined!"
		return 1
	fi	
	
	return 0
}

start() {
        ebegin "Starting Domoticz"
		start-stop-daemon --start --quiet --user $DOMOTICZ_USER --make-pidfile --pidfile $PIDFILE --background --exec $DAEMON --  -dbase $DBASE -wwwroot $WWWROOT -log $LOGFILE -approot $APPROOT
        eend $?
}

stop() {
        ebegin "Stopping Domoticz"
        start-stop-daemon --stop --quiet --pidfile $PIDFILE
        eend $?
}
