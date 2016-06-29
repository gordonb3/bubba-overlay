#!/bin/sh

LOG=/var/tmp/bridge.log

function bridge_up {
    /usr/bin/nmcli connection up ifname eth1
    /usr/bin/systemctl start hostapd &>> $LOG
}


function bridge_down {
    /usr/bin/systemctl stop hostapd &>> $LOG
    MASTER=$(/sbin/brctl show | | grep "^br0\s")
    if [ "${MASTER}" != "" ];then
        brctl delbr br0
    fi
}


if [ "$1" = "br0" ]; then
echo "Bridge interface action" >> $LOG
    if [ "$2" = "up" ]; then
echo "    action = up" >> $LOG
        bridge_up
    fi

    if [ "$2" = "down" ]; then
echo "    action = down" >> $LOG
        bridge_down
    fi
fi
