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
# Jun 2019 - gordonb3 <gordon@bosvangennip.nl>
#  - correct for different behaviour of fdisk on DOS partition tables
#  - correct swap partition type ID for GPT
#
# Oct 2019 - gordonb3 <gordon@bosvangennip.nl>
#  - allow installer to run from a different mountpoint than /
#  - installer may now also be used to replace the current running system
#
# May 2023 - gordonb3 <gordon@bosvangennip.nl>
#  - injection of systemd derived methods in openrc caused installer to
#       configure boot.ini for systemd always. 
#

declare -r LOG=/var/log/gentoo_install.log
declare -r TARGETDEV=sda
declare -i SIZE=20
declare -i STEP=0
declare -i NSTEPS=3
declare WIPE=false
declare RSYNC_OPTIONS="-avx --delete"
declare SOURCEDEV SOURCEBOOT SOURCEROOT TARGETBOOT TARGETROOT TARGETHOME


# init: get_source_dirs()
# retrieve the device and mountpoints that contain this script

get_source_dirs() {
	local SCRIPTNAME SCRIPTPATH

	SCRIPTNAME=${BASH_SOURCE[0]}
	while [ -h "${SCRIPTNAME}" ]; do
		SCRIPTPATH=$(dirname "${SCRIPTNAME}")
		SCRIPTNAME=$(readlink "${SCRIPTNAME}")
		[[ ${SCRIPTNAME} != /* ]] && SCRIPTNAME="${SCRIPTPATH}/${SCRIPTNAME}"
	done
	SCRIPTPATH=$(dirname "${SCRIPTNAME}")
	[[ ${SCRIPTPATH} != /* ]] && SCRIPTPATH=$(cd -P "${SCRIPTPATH}" >/dev/null 2>&1 && pwd)

	SOURCEDEV=$(df ${SCRIPTPATH} | grep "^/" | awk '{print $1}' | sed "s/[0-9]$//")
	if [ ${SOURCEDEV} == "/dev/root" ]; then
		SOURCEDEV=$(findmnt -n -o SOURCE / | sed "s/[0-9]$//")
	fi
	if [ ${SOURCEDEV} == "/dev/${TARGETDEV}" ]; then
		echo "ERROR - Cannot install onto myself - exiting" >&2
		exit 1
	fi

	SOURCEROOT=$(df ${SCRIPTPATH} | grep "^/" | awk '{print $6}')
	SOURCEBOOT=$(lsblk -n ${SOURCEDEV}1 | awk '{print $7}')
}

# init: get_target_dirs()
# retrieve the current mountpoints of our targets

get_target_dirs() {
	TARGETBOOT=$(lsblk -n /dev/${TARGETDEV}1 2>/dev/null | awk '{print $7}')
	TARGETROOT=$(lsblk -n /dev/${TARGETDEV}3 2>/dev/null | awk '{print $7}')
	TARGETHOME=$(lsblk -n /dev/${TARGETDEV}4 2>/dev/null | awk '{print $7}')
}

# init: read_settings()
# if exist, read install.ini to fetch possible overrides of default settings

read_settings() {
	if [ -f ${SOURCEROOT}/root/install.ini ]; then
		source ${SOURCEROOT}/root/install.ini
	fi
}

# pre-install check: verify_partition_table()
# By default the installer is configured to preserve the `home` partition. This routine
# verifies whether the partition table matches the required layout to obey that setting.
#
# If the disk layout does not match this will setup the installer to wipe the entire disk

verify_partition_table() {
	( ${WIPE} ) && return

	local PTABLE SDAPARTINFO

	# determine type of partition table
	PTABLE=$(fdisk -l /dev/${TARGETDEV} | grep "Disklabel type" | awk '{print $NF}')

	# get drive partition info
	if [ "${PTABLE}" == "gpt" ]; then
		SDAPARTINFO=$(fdisk -l /dev/${TARGETDEV} | grep -e "${TARGETDEV}[1-9]" | grep "Linux" | awk '{print $1$5$7}')
	else
		SDAPARTINFO=$(fdisk -l /dev/${TARGETDEV} | grep -e "${TARGETDEV}[1-9]" | grep "Linux" | awk '{print $1$5$8"filesystem"}')
	fi

	if (echo ${SDAPARTINFO} | grep -qv ${TARGETDEV}1); then
		# partition table is empty
		WIPE=true
	else
		# verify current partition layout
		if (echo ${SDAPARTINFO} | grep -qvE "${TARGETDEV}164Mfile.*${TARGETDEV}21Gswap.*${TARGETDEV}3[2-9][0-9]+Gfile.*${TARGETDEV}4"); then
			# current partition table on /dev/${TARGETDEV} is not suited for this installation
			WIPE=true
		fi
	fi
}

# pre-install check: check_init_systems()
# when replacing the current running system we need to take extra precautions
# if we are moving from systemd to openrc

check_init_systems() {
	[[ ${TARGETROOT} != / ]] && return

	local SOURCEINIT TARGETINIT
	if [ ! -z $(ls -d ${SOURCEROOT}/var/db/pkg/sys-apps/systemd* 2>/dev/null) ]; then
		SOURCEINIT=systemd
	fi

	if (cat /proc/cmdline | grep -q systemd); then
		TARGETINIT=systemd
	fi

	echo

	if [ "${SOURCEINIT}:${TARGETINIT}" == ":systemd" ]; then
		echo "WARNING - you are converting your current running system"
		echo "from systemd init system to openrc."
		echo
		echo "Because deleting the systemd files will cause the system"
		echo "to become uncontrollable they will have to be retained"
		echo "until you reboot into your new system. To clear the system"
		echo "from these rogue files you must remount this image after"
		echo "restart and run this installer a second time"
		echo
		echo "Type (upper case) YES and press Enter if you understand"
		echo "and wish to proceed."
		read -p "Any other entry quits without installing: " REPLY
		if [ "${REPLY}" != "YES" ]; then
			echo "You did not type YES - exiting" >&2
			exit 1
		fi
		RSYNC_OPTIONS=$(echo ${RSYNC_OPTIONS} | sed "s/\-\-delete//g")
		NSTEPS+=3
		return
	fi

	echo "WARNING - you are about to overwrite your current running system."
	echo
	echo "Type (upper case) YES and press Enter if you wish to proceed."
	read -p "Any other entry quits without installing: " REPLY
	if [ "${REPLY}" != "YES" ]; then
		echo "You did not type YES - exiting" >&2
		exit 1
	fi
}


# pre-install: rotate_logs()
#

rotate_logs() {
	[[ ! -e ${LOG} ]] && return

	local -i OLDVERSION NEWVERSION
	local LOGFILE
	ls -1r ${LOG}.* 2>/dev/null | while read LOGFILE; do
		OLDVERSION=$(echo ${LOGFILE} | awk -F. '{print $NF}')
		if [ ${OLDVERSION} -gt 3 ]; then
			rm ${LOGFILE}
		else
			NEWVERSION=${OLDVERSION}+1
			mv ${LOGFILE} ${LOG}.${NEWVERSION}
		fi
	done
	mv ${LOG} ${LOG}.0
}


# install: create_partitions()
# create a new partition table with four partitions on our target disk:
#  - boot, swap, root and home

create_partitions() {
	( ${WIPE} ) || return

	# verify that no partitions on the target disk are currently mounted
	if (grep -q "/dev/${TARGETDEV}" /proc/mounts); then
		echo "Please unmount any /dev/${TARGETDEV} partitions first - exiting" >&2
		exit 1
	fi

	local PTABLE

	# determine type of partition table to create
	PTABLE=$(fdisk -l /dev/${TARGETDEV} | grep "Disklabel type" | awk '{print $NF}')
	if [ "${PTABLE}" != "dos" ] && [ "${PTABLE}" != "gpt" ]; then
#		echo "NOTICE - Unknown partition table or disk not initialized"
		PTABLE=dos
	fi
	if [ "${PTABLE}" != "gpt" ]; then
		if [ ! -z $(fdisk -l /dev/${TARGETDEV} | grep TiB | awk '{print 4000000000-$(NF-1)}' | grep "^\-") ]; then
			# cannot use DOS partition table because the disk contains more than 4,000,000,000 sectors
			PTABLE=gpt
		fi
	fi

	if [ ${SIZE} -lt 20 ];then
		echo "NOTICE - resetting SIZE to the default value of 20GiB as the specified value is too small to reliably run our system."
		SIZE=20
	fi

	STEP+=1
	echo "Step ${STEP} of ${NSTEPS}: creating new \"${PTABLE}\" partition table on /dev/${TARGETDEV}..."

	# create new partition table
	if [ "${PTABLE}" == "dos" ]; then
		echo -e "o\nw" | fdisk /dev/${TARGETDEV} >>"${LOG}" 2>&1
	else
		echo -e "g\nw" | fdisk /dev/${TARGETDEV} >>"${LOG}" 2>&1
	fi
	echo 1 > /sys/block/${TARGETDEV}/device/rescan

	# create partitions
	if [ "${PTABLE}" == "dos" ]; then
		echo -e "n\np\n1\n\n+64M\nn\np\n2\n\n+1G\nt\n2\n82\nn\np\n3\n\n+${SIZE}G\nn\np\n\n\np\nw" | fdisk /dev/${TARGETDEV} >>"${LOG}" 2>&1
	else
		echo -e "n\n1\n\n+64M\nn\n2\n\n+1G\nt\n2\n19\nn\n3\n\n+${SIZE}G\nn\n4\n\n\np\nw" | fdisk /dev/${TARGETDEV} >>"${LOG}" 2>&1
	fi
	echo 1 > /sys/block/${TARGETDEV}/device/rescan
}

# install: format_partitions()
# format our newly created partitions:
#  - boot:ext3, swap:swap, root:ext4 and home:ext4

format_partitions() {
	( ${WIPE} ) || return

	STEP+=1
	echo "Step ${STEP} of ${NSTEPS}: formatting partitions on /dev/${TARGETDEV}..."

	mkfs.ext3 -F -L "boot" /dev/${TARGETDEV}1 >>"${LOG}" 2>&1
	mkswap -L "swap" /dev/${TARGETDEV}2 >>"${LOG}" 2>&1
	mkfs.ext4 -F -L "root" /dev/${TARGETDEV}3 >>"${LOG}" 2>&1
	mkfs.ext4 -F -L "home" /dev/${TARGETDEV}4 >>"${LOG}" 2>&1
}

# install: mount_targets()
# if not already mounted, mount our targets now

mount_targets() {
	STEP+=1
	echo "Step ${STEP} of ${NSTEPS}: mounting boot and root partitions from /dev/${TARGETDEV}..."

	[[ "${TARGETROOT}" == "/" ]] && [[ -z "${TARGETBOOT}" ]] && mount /dev/${TARGETDEV}1 /boot >>"${LOG}" 2>&1 && TARGETBOOT=/boot
	[[ -z ${TARGETBOOT} ]] && mkdir -p /mnt/sdaboot && mount /dev/${TARGETDEV}1 /mnt/sdaboot >>"${LOG}" 2>&1 && TARGETBOOT=/mnt/sdaboot
	[[ -z ${TARGETROOT} ]] && mkdir -p /mnt/sdaroot && mount /dev/${TARGETDEV}3 /mnt/sdaroot >>"${LOG}" 2>&1 && TARGETROOT=/mnt/sdaroot
	[[ -z ${TARGETHOME} ]] && mkdir -p /mnt/sdahome && mount /dev/${TARGETDEV}4 /mnt/sdahome >>"${LOG}" 2>&1 && TARGETHOME=/mnt/sdahome
}

# install: copy_system()
# copy system and bootfiles

copy_system() {
	STEP+=1
	echo "Step ${STEP} of ${NSTEPS}: copying system and bootfiles (please be patient)..."

	mkdir -p ${TARGETBOOT}/boot >>"${LOG}" 2>&1
	cp -ax ${SOURCEROOT}/root/root-on-sda3-kernel/{uImage,config,System.map} ${TARGETBOOT}/boot/ >>"${LOG}" 2>&1
	if [ -e ${SOURCEROOT}/root/root-on-sda3-kernel/boot.ini ]; then
		# this is not our final kernel
		[[ -z "${SOURCEBOOT}" ]] && mount ${SOURCEDEV}1 ${SOURCEROOT}/boot >>"${LOG}" 2>&1 && SOURCEBOOT=${SOURCEROOT}/boot
		rsync ${RSYNC_OPTIONS} --exclude "install" --exclude "boot*" ${SOURCEBOOT}/ ${TARGETBOOT} >>"${LOG}" 2>&1
		cp -ax ${SOURCEROOT}/root/root-on-sda3-kernel/boot.ini ${TARGETBOOT} >>"${LOG}" 2>&1
		chmod -x ${TARGETBOOT}/{config*,System.map*,firmware/*} >>"${LOG}" 2>&1

		# make sure that we configure for the right init system
		if [ ! -z $(ls -d ${SOURCEROOT}/var/db/pkg/sys-apps/systemd-[0-9]* 2>/dev/null) ]; then
			# systemd init
			if ( ! grep -q "^\s*INIT=" ${TARGETBOOT}/boot.ini ); then
				if ( grep -q "^\s*#\s*INIT=" ${TARGETBOOT}/boot.ini ); then
					sed "s/^\s*#\s*INIT=.*$/INIT=\"systemd\"/" -i ${TARGETBOOT}/boot.ini
				else
					echo -e "\n# enable this to boot into systemd service manager (default: openrc)" >> ${TARGETBOOT}/boot.ini
					echo -e "INIT=\"systemd\"" >> ${TARGETBOOT}/boot.ini
				fi
			fi
		else
			# openrc init
			sed "s/^\s*INIT/#INIT/" -i ${TARGETBOOT}/boot.ini
		fi
	fi

	cp -ax ${SOURCEROOT}/dev ${SOURCEROOT}/tmp ${TARGETROOT} >>"${LOG}" 2>&1
	for dir in bin etc lib opt root sbin usr; do
		rsync ${RSYNC_OPTIONS} ${SOURCEROOT}/${dir} ${TARGETROOT}/ >>"${LOG}" 2>&1
	done
	rsync ${RSYNC_OPTIONS} --exclude "${LOG}*" ${SOURCEROOT}/var ${TARGETROOT}/ >>"${LOG}" 2>&1

	if ( $WIPE ); then
		rsync ${RSYNC_OPTIONS} ${SOURCEROOT}/home/ ${TARGETHOME} >>"${LOG}" 2>&1
	else
		cp -ax ${SOURCEROOT}/home/admin ${TARGETHOME} >>"${LOG}" 2>&1
	fi
	mkdir -p ${TARGETROOT}/{boot,home,media,mnt,proc,run,sys} >>"${LOG}" 2>&1
	cp -ax ${SOURCEROOT}/root/fstab-on-b3 ${TARGETROOT}/etc/fstab >>"${LOG}" 2>&1
}

# install: sync_and_unmount()
# sync file system, unmount all dynamically mounted partitions and delete temporary directories

sync_and_unmount() {
	STEP+=1
	echo "Step ${STEP} of ${NSTEPS}: syncing filesystems and unmounting..."
	sync >>"${LOG}" 2>&1
	local MOUNTPOINT
	ls -1d /mnt/sda* 2>/dev/null | while read MOUNTPOINT; do
		umount -l ${MOUNTPOINT} >>"${LOG}" 2>&1
		rmdir ${MOUNTPOINT} >>"${LOG}" 2>&1
	done
	umount -l ${SOURCEBOOT} >>"${LOG}" 2>&1
}

# post-install: warn_installation_incomplete
# set up notifications that the installation needs to be continued after reboot

warn_installation_incomplete() {

	echo 'Stage 1 of the installation process has been completed.'
	echo 'After rebooting into your new system please run this installer again.'

	[[ ${TARGETROOT} != / ]] && return

	echo >> ${TARGETROOT}/etc/motd
	echo "==============================================================================" >> /etc/motd
	echo "|            WARNING: installation was not fully completed                   |" >> /etc/motd
	echo "|                     please run the installer again                         |" >> /etc/motd
	echo "==============================================================================" >> /etc/motd

	echo -n "${NSTEPS}" > ${TARGETROOT}/var/lib/bubba/install.stage

	exit
}

# post-install: clear_rogue_files
#
clear_rogue_files() {
        echo "Entering stage 2 of the installation process."
	NSTEPS=$(cat ${TARGETROOT}/var/lib/bubba/install.stage)
	STEP=${NSTEPS}-3
	mount_targets
	copy_system
	sync_and_unmount

	echo
	echo 'All done! You can reboot into your new system now.'
	exit
}



# main()

echo "Install Gentoo -> /dev/${TARGETDEV} (B3's internal HDD)"
echo

# init
get_source_dirs
get_target_dirs
read_settings
[[ -e ${TARGETROOT}/var/lib/bubba/install.stage ]] && clear_rogue_files

# pre-install checks
( ! ${WIPE} ) && verify_partition_table
if ( ${WIPE} ); then
	if [[ ${TARGETROOT} == / ]]; then
		echo "ERROR - unable to proceed" >&2
		echo "You are attempting to overwrite the current running system but" >&2
		echo "your HDD needs to be reformatted - exiting" >&2
		exit 1
	fi
	echo "WARNING - will delete anything currently on HDD"
	echo "(including any existing Excito Debian system)"
else
	echo "WARNING - will delete existing system on HDD"
	echo "your home partition (/dev/${TARGETDEV}4) will be retained"
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
[[ ${TARGETROOT} == / ]] && check_init_systems

# install
rotate_logs
echo "Installing: check '$LOG' in case of errors"
( ${WIPE} ) && NSTEPS+=2
( ${WIPE} ) && create_partitions
( ${WIPE} ) && format_partitions
mount_targets
copy_system
sync_and_unmount

echo
[[ ${STEP} -lt ${NSTEPS} ]] && warn_installation_incomplete
echo 'All done! You can reboot into your new system now.'

