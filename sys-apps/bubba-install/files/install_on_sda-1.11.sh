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
#  - create a fourth partition to hold /home
#       prevents users filling up the root partition through exposed services
#
# Aug 2018 - gordonb3 <gordon@bosvangennip.nl>
#  - conditionally keep home partition when upgrading from a system that
#       already has a correct disk layout
#  - adjust for modified boot partition content with uImage using kexec to
#       load the final kernel
#

set -e
set -u
set -o pipefail

LOG=/var/log/gentoo_install.log
WIPE=false
SIZE=20

if [ -f /root/install.ini ]; then
	source /root/install.ini
fi


if (echo $SIZE | grep -qvE "^[0-9]+$"); then
	echo "SIZE is not a number. Please fix install.ini - exiting" >&2
	exit 1
fi


if (grep -q "/dev/sda" /proc/mounts); then
	echo "Please unmount any /dev/sda partitions first - exiting" >&2
	exit 1
fi


if ( ! $WIPE ); then
	# get drive partition info
	sdapartinfo=$(fdisk -l /dev/sda | grep -e "sda[1-9]" | grep "Linux" | awk '{print $1$5$7}')

	if (echo $sdapartinfo | grep -qv sda1); then
		# partition table is empty
		WIPE=true
	else
		# verify current partition layout
		if (echo $sdapartinfo | grep -qvE "sda164Mfile.*sda21Gswap.*sda3[2-9][0-9]+Gfile.*sda4"); then
			# current partition table on /dev/sda is not suited for this installation
			WIPE=true
		fi
	fi
fi


STEP=1
NSTEPS=4

echo "Install Gentoo -> /dev/sda (B3's internal HDD)"
echo
if ( $WIPE ); then
	echo "WARNING - will delete anything currently on HDD"
	echo "(including any existing Excito Debian system)"
else
	echo "WARNING - will delete existing system on HDD"
	echo "your home partition (/dev/sda4) will be retained"
fi
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


if ( $WIPE ); then
	NSTEPS=$((NSTEPS+1))
	echo "Step $STEP of $NSTEPS: creating new \"${ptable}\" partition table on /dev/sda..."
	STEP=$((STEP+1))

	if [ $SIZE -lt 20 ];then
		echo "NOTICE - resetting SIZE to the default value of 20GiB as the specified value is too small to reliably run our system."
		SIZE=20
	fi

	ptable=$(fdisk -l /dev/sda | grep "Disklabel type" | awk '{print $NF}')
	if [ ${ptable} != "dos" ] && [ ${ptable} != "gpt" ]; then
		echo "NOTICE - Unknown partition table or disk not initialized"
		ptable=dos
	fi
	if [ ${ptable} != "gpt" ]; then
		if [ ! -z $(fdisk -l /dev/sda | grep TiB | awk '{print 4000000000-$(NF-1)}' | grep "^\-") ]; then
			ptable=gpt
		fi
	fi

	# create new partition table
	if [ ${ptable} == "dos" ]; then
		echo -e "o\nw" | fdisk /dev/sda >>"${LOG}" 2>&1
	else
		echo -e "g\nw" | fdisk /dev/sda >>"${LOG}" 2>&1
	fi
	echo 1 > /sys/block/sda/device/rescan

	# create partitions
	echo -e "n\n1\n\n+64M\nn\n2\n\n+1G\nt\n2\n14\nn\n3\n\n+${SIZE}G\nn\n4\n\n\np\nw" | fdisk /dev/sda >>"${LOG}" 2>&1
fi


echo "Step $STEP of $NSTEPS: formatting partitions on /dev/sda..."
STEP=$((STEP+1))
echo 1 > /sys/block/sda/device/rescan
mkfs.ext3 -F -L "boot" /dev/sda1 >>"${LOG}" 2>&1
mkswap -L "swap" /dev/sda2 >>"${LOG}" 2>&1
mkfs.ext4 -F -L "root" /dev/sda3 >>"${LOG}" 2>&1
if ( $WIPE ); then
	mkfs.ext4 -F -L "home" /dev/sda4 >>"${LOG}" 2>&1
fi


echo "Step $STEP of $NSTEPS: mounting boot and root partitions from /dev/sda..."
STEP=$((STEP+1))
mkdir -p /mnt/{sdaboot,sdaroot,sdahome} >>"${LOG}" 2>&1
mount /dev/sda1 /mnt/sdaboot >>"${LOG}" 2>&1
mount /dev/sda3 /mnt/sdaroot >>"${LOG}" 2>&1
mount /dev/sda4 /mnt/sdahome >>"${LOG}" 2>&1


echo "Step $STEP of $NSTEPS: copying system and bootfiles (please be patient)..."
STEP=$((STEP+1))
mkdir -p /mnt/sdaboot/boot >>"${LOG}" 2>&1
cp -ax /root/root-on-sda3-kernel/{uImage,config,System.map} /mnt/sdaboot/boot/ >>"${LOG}" 2>&1
if [ -e /root/root-on-sda3-kernel/boot.ini ]; then
	# this is not our final kernel
	cp -ax /root/root-on-sda3-kernel/boot.ini /mnt/sdaboot/ >>"${LOG}" 2>&1
	mount /boot 2>/dev/null
	cp -ax /boot/{vmlinuz*,config*,System.map*,firmware} /mnt/sdaboot/ >>"${LOG}" 2>&1
	chmod -x /mnt/sdaboot/{config*,System.map*,firmware/*} >>"${LOG}" 2>&1

	# make sure that we configure for the right init system
	if (cat /proc/cmdline | grep -q systemd); then
		# systemd init
		if ( ! grep -q "^\s*INIT=" /mnt/sdaboot/boot.ini ); then
			if ( grep -q "^\s*#\s*INIT=" /mnt/sdaboot/boot.ini ); then
				sed "s/^\s*#\s*INIT=.*$/INIT=\"systemd\"/" -i /mnt/sdaboot/boot.ini
			else
				echo -e "\n# enable this to boot into systemd service manager (default: openrc)" >> /mnt/sdaboot/boot.ini
				echo -e "INIT=\"systemd\"" >> /mnt/sdaboot/boot.ini
			fi
			
		fi
	else
		# openrc init
		sed "s/^\s*INIT/#INIT/" -i /mnt/sdaboot/boot.ini
	fi
fi
cp -ax /bin /dev /etc /lib /opt /root /sbin /tmp /usr /var /mnt/sdaroot/ >>"${LOG}" 2>&1
if ( $WIPE ); then
	cp -ax /home/* /mnt/sdahome/ >>"${LOG}" 2>&1
else
	cp -ax /home/admin /mnt/sdahome/ >>"${LOG}" 2>&1
fi
mkdir -p /mnt/sdaroot/{boot,home,media,mnt,proc,run,sys} >>"${LOG}" 2>&1
cp /root/fstab-on-b3 /mnt/sdaroot/etc/fstab >>"${LOG}" 2>&1


echo "Step $STEP of $NSTEPS: syncing filesystems and unmounting..."
STEP=$((STEP+1))
sync >>"${LOG}" 2>&1
umount -l /mnt/{sdaboot,sdaroot,sdahome} >>"${LOG}" 2>&1
rmdir /mnt/{sdaboot,sdaroot,sdahome} >>"${LOG}" 2>&1

echo 'All done! You can reboot into your new system now.'

