
#!/bin/bash
# Copyright (c) 2015 sakaki <sakaki@deciban.com>
# License: GPL 3.0+
# NO WARRANTY
#
# Installs Gentoo system on /dev/sda, using default settings.
# Adapt to your requirements.
# WARNING - will delete the contents of /dev/sda!
#
# Changes:
#
# May 2016 - gordonb3 <gordon@bosvangennip.nl>
#  - auto detect what partition table type to use ('dos' or 'gpt')
#       will force 'gpt' if disk size > 2GiB
#       otherwise use existing or default to 'dos' if unsupported
#
#  - create a fourth partition to hold /home
#       prevents users filling up the root partition through exposed services
#
#

set -e
set -u
set -o pipefail

LOG=/var/log/gentoo_install.log

if grep -q "/dev/sda" /proc/mounts; then
    echo "Please unmount any /dev/sda partitions first - exiting" >&2
    exit 1
fi
echo "Install Gentoo -> /dev/sda (B3's internal HDD)"
echo
echo "WARNING - will delete anything currently on HDD"
echo "(including any existing Excito Debian system)"
echo "Please make sure you have adequate backups before proceeding"
echo
echo "Type (upper case) INSTALL and press Enter to continue"
read -p "Any other entry quits without installing: " REPLY
if [[ ! "${REPLY}" == "INSTALL" ]]
then
    echo "You did not type INSTALL - exiting" >&2
    exit 1
fi
echo "Installing: check '$LOG' in case of errors"

ptable=$(fdisk -l /dev/sda | grep "Disklabel type" | awk '{print $NF}')
if [ ${ptable} != "dos" && ${ptable} != "gpt" ]; then
    echo "Unknown partition table or disk not initialized"
    ptable=dos
fi
if [ ${ptable} != "gpt" ]; then
    if [ ! -z $(fdisk -l /dev/sda | grep TiB | awk '{print 4000000000-$(NF-1)}' | grep "^\-") ]; then
        ptable=gpt
    fi
fi
echo "Step 1 of 5: creating new \"${ptable}\" partition table on /dev/sda..."
echo "g
n
1

+64M
n
2

+1G
t
2
14
n
3

+20G
n
4


p
w" | fdisk /dev/sda >"${LOG}" 2>&1

echo "Step 2 of 5: formatting partitions on /dev/sda..."
echo 1 > /sys/block/sda/device/rescan
mkfs.ext3 -F -L "boot" /dev/sda1 >>"${LOG}" 2>&1
mkswap -L "swap" /dev/sda2 >>"${LOG}" 2>&1
mkfs.ext4 -F -L "root" /dev/sda3 >>"${LOG}" 2>&1
mkfs.ext4 -F -L "home" /dev/sda4 >>"${LOG}" 2>&1

echo "Step 3 of 5: mounting boot and root partitions from /dev/sda..."
mkdir -p /mnt/{sdaboot,sdaroot,sdahome} >>"${LOG}" 2>&1
mount /dev/sda1 /mnt/sdaboot >>"${LOG}" 2>&1
mount /dev/sda3 /mnt/sdaroot >>"${LOG}" 2>&1
mount /dev/sda4 /mnt/sdahome >>"${LOG}" 2>&1

echo "Step 4 of 5: copying system and bootfiles (please be patient)..."
mkdir -p /mnt/sdaboot/boot >>"${LOG}" 2>&1
cp -ax /root/root-on-sda3-kernel/{uImage,config,System.map} /mnt/sdaboot/boot/ >>"${LOG}" 2>&1
cp -ax /bin /dev /etc /lib /opt /root /sbin  /tmp /usr /var /mnt/sdaroot/ >>"${LOG}" 2>&1
cp -ax /home/* /mnt/sdahome/ >>"${LOG}" 2>&1
mkdir -p /mnt/sdaroot/{boot,home,media,mnt,proc,run,sys} >>"${LOG}" 2>&1
cp /root/fstab-on-b3 /mnt/sdaroot/etc/fstab >>"${LOG}" 2>&1

echo "Step 5 of 5: syncing filesystems and unmounting..."
sync >>"${LOG}" 2>&1
umount -l /mnt/{sdaboot,sdaroot,sdahome} >>"${LOG}" 2>&1
rmdir /mnt/{sdaboot,sdaroot,sdahome} >>"${LOG}" 2>&1

echo 'All done! You can reboot into your new system now.'

