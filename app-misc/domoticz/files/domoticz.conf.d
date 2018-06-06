# /etc/conf.d/domoticz

WWWROOT="/opt/domoticz/www/"
LOGFILE="/var/log/domoticz.log"
DBASE="/var/lib/domoticz/domoticz.db"
APPROOT="/opt/domoticz/"

EXTRAPARMS="-www 10080 -nowwwpwd -loglevel 0 -userdata /var/lib/domoticz/ -wwwcompress static"
