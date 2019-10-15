# /etc/conf.d/oikomaticz

WWWROOT="/opt/oikomaticz/www/"
LOGFILE="/var/log/oikomaticz.log"
DBASE="/var/lib/oikomaticz/oikomaticz.db"
APPROOT="/opt/oikomaticz/"

EXTRAPARMS="-www 8080 -nowwwpwd -sslwww 0 -loglevel normal,status,error -userdata /var/lib/oikomaticz/ -wwwcompress static"
