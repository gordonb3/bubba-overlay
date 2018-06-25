# /etc/conf.d/domoticz

WWWROOT="/opt/domoticz/www/"
LOGFILE="/var/log/domoticz.log"
DBASE="/var/lib/domoticz/domoticz.db"
APPROOT="/opt/domoticz/"

EXTRAPARMS="-www 8080 -nowwwpwd -sslwww 443 -loglevel normal,status,error -userdata /var/lib/domoticz/ -wwwcompress static"
