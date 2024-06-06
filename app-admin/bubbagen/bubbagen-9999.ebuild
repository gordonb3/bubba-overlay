# Copyright 2015-2022 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

inherit git-r3

EGIT_REPO_URI="https://github.com/gordonb3/${PN}.git"

DESCRIPTION="The Bubba main package"
HOMEPAGE="https://github.com/gordonb3/bubbagen"
KEYWORDS=""
LICENSE="GPL-3+"
#SRC_URI="https://github.com/gordonb3/bubbagen/archive/v${PV}.tar.gz -> ${PF}.tgz"
VMAJOR=${PV:0:4}
SLOT="0/${VMAJOR}"
RESTRICT="mirror"
IUSE="bindist systemd"

# Conflicts/replaces Sakaki's b3-init-scripts
DEPEND="
	!sys-apps/b3-init-scripts
	>=virtual/udev-215
	>=sys-apps/ethtool-3.12.1
"

RDEPEND="${DEPEND}
	app-admin/bubba-admin
	app-admin/bubba-manual
	arm? ( sys-power/bubba-buttond )
"

REMOVELIST=""
IS_BINDIST=""
KERNEL_MAJOR=""
KERNEL_MINOR=""
PROFILE=0

pkg_setup() {
	[[ -e ${ROOT}/var/lib/bubba/bubba-default-config.tgz ]] || return

	# find unaltered portage config files from a previous bubbagen release
	mkdir -p ${WORKDIR}/oldconfig
	cd ${WORKDIR}/oldconfig
	tar -xzf ${ROOT}/var/lib/bubba/bubba-default-config.tgz
	find etc/portage -type f | while read FILE; do
		if ( ! diff -q ${FILE} /${FILE} 2&> /dev/null ); then
			# file has been altered from default
			rm -f ${FILE}
		fi
	done
	cd - > /dev/null

	# determine what bindist state our current system is in
	IS_BINDIST=$(equery u dev-libs/openssl | grep bindist)

	# get kernel version
	KERNEL_MAJOR=$(uname -r | cut -d. -f1)
	KERNEL_MINOR=$(uname -r | cut -d. -f2)

	# get profile version
	PROFILE=$(readlink /etc/portage/make.profile | sed -e "s/[^0-9]//g" -e "s/^\(..\).*/\1/")
}

src_prepare() {
	eapply_user

	# Git does not support empty folders
	# clean up the bogus content here.
	find ${S} -name ~nofiles~ -exec rm {} \;

	if use systemd; then
		cp -a ${S}/systemd/* ${S}/
		cd ${S}/etc/local.d
		ls -1 | while read FILE; do
			grep -q -m1 rc-service ${FILE} && rm ${FILE}
		done
		cd - > /dev/null
	fi

	# if enabled, include config files required to prevent bindist conflicts
	use bindist && [[ -d ${S}/bindist ]] && cp -a ${S}/bindist/* ${S}/

	# correct for different settings between B2 and B3
	use ppc && rm etc/portage/package.use/sysvinit

	# remove xtables-addons 3.x mask when kernel >= 4.15
	XT_ADDONS="/etc/portage/package.mask/xtables-addons"
	[[ ${KERNEL_MAJOR} -gt 4 ]] && REMOVELIST="${XT_ADDONS}" && rm -f ${S}${XT_ADDONS}
	[[ ${KERNEL_MAJOR} -eq 4 ]] && [[ ${KERNEL_MINOR} -gt 14 ]] && REMOVELIST="${XT_ADDONS}" && rm -f ${S}${XT_ADDONS}
}

src_compile() {
	if [ -d ${WORKDIR}/oldconfig ]; then
		# build list of portage config files that need to be removed
		cd ${WORKDIR}/oldconfig
		find etc/portage -type f | while read FILE; do
			[[ -e ${S}/${FILE} ]] || REMOVELIST="${REMOVELIST} /${FILE}"
		done
		cd - > /dev/null
	fi

	if [ ${PROFILE} -ge 23 ]; then
		rm ${S}/etc/portage/package.use.force/merged-usr
		rmdir ${S}/etc/portage/package.use.force 2>/dev/null
	fi

	elog "Create bubba-default-config archive"
	tar -czf bubba-default-config.tgz etc
}

src_install() {
	# construct version from git info
	LAST_TAG=$(git describe --abbrev=0 --tags)
	LAST_COMMIT=$(date -d @$(git show -s --format=%ct) +"%y%m%d")
        dodir /etc/bubba
	echo "${LAST_TAG:0:5}.$((${PV:5}+4))_pre${LAST_COMMIT}" > ${ED}/etc/bubba/bubba.version

	insinto /var/lib/bubba
	doins bubba-default-config.tgz

	elog "Installing portage config files"
	rm -f etc/portage/make.conf
	insinto /etc
	cp -aR etc/portage ${ED}/etc/
	cp -aR etc/local.d ${ED}/etc/

	exeinto /opt/bubba/sbin
	doexe sbin/bubba-restore-defaults.sh
	fperms 750 /opt/bubba/sbin/bubba-restore-defaults.sh

	exeinto /usr/share/distcc
	doexe usr/share/distcc/distcc-fix

	if use arm; then
		elog "Add B3 udev rules"
		insinto /lib/udev/rules.d
		newins	${FILESDIR}/marvell-fix-tso.udev 50-marvell-fix-tso.rules
		newins	${FILESDIR}/net-name-use-custom.udev 70-net-name-use-custom.rules
	fi
}

pkg_postinst() {
	if [[ ! -z "${REMOVELIST}" ]]; then
		elog "Removed obsolete portage config files from previous version"
		rm -f ${REMOVELIST}
	fi

	if use bindist; then
		CONF_BINDIST=$(grep "^USE=" /etc/portage/make.conf | cut -d# -f1 | grep bindist)
		if [[ -z "${CONF_BINDIST}" ]]; then
			EMPTYUSELINE=$(grep -m1 -n "^USE=\"\"" /etc/portage/make.conf | cut -d: -f1)
			if [[ -z "${EMPTYUSELINE}" ]]; then
				sed -e "${EMPTYUSELINE} s/^USE=\"\"/USE=\"bindist\"/" -i /etc/portage/make.conf
			else
				LINENUMBER=$(grep -m1 -n "^USE=\"" /etc/portage/make.conf | cut -d: -f1)
				sed -e "${LINENUMBER} s/^USE=\"/USE=\"bindist\"\nUSE=\"\${USE} /" -i /etc/portage/make.conf
			fi
			elog "Added bindist USE flag to your global make.conf"
		fi

		# enforce overwrite of bindist conf files
		find /etc/portage/ -name ._cfg*bindist* | while read FILE; do
			CONFFILE=$(echo ${FILE} | sed "s/\._cfg[0-9]*_//")
			rm -f ${CONFFILE}
			mv ${FILE} ${CONFFILE}
		done
	else
		grep -q "^USE=\"[^#]*bindist" /etc/portage/make.conf && elog "Removed bindist USE flag from your global make.conf"
		sed -e "s/^\(USE=\"[^#]*\)bindist\(.*\)$/\1\2/" -e "s/ *\" */\"/g" -e "s/   */ /g" -i /etc/portage/make.conf

		BINDIST_CONFS=$(find /etc/portage -name *bindist*)
		[[ ! -z "${BINDIST_CONFS}" ]] && elog "Removed package specific restrictions only required for bindist"
		rm -f ${BINDIST_CONFS}
	fi

	# -- hotfixes --

	# 24-05-31 verify that PERL_FEATURES="ithreads" is set in the global make.conf
	if (! grep -q "PERL_FEATURES.*ithreads" /etc/portage/make.conf); then
		if (grep -q PERL_FEATURES /etc/portage/make.conf); then
			eval $(grep PERL_FEATURES /etc/portage/make.conf)
			sed -e "/PERL_FEATURES/cPERL_FEATURES=\"${PERL_FEATURES} ithreads\"" -i /etc/portage/make.conf
		else
			echo -e "\nPERL_FEATURES=\"ithreads\"" >> /etc/portage/make.conf
		fi
	fi

	# 24-04-21 correct faulty LMS server uuid published in former releases
	if (grep -q "uuid: 7b0490d8" /var/lib/logitechmediaserver/preferences/server.prefs); then
		sed -e "/^server_uuid/d" -i /var/lib/logitechmediaserver/preferences/server.prefs
		sed -e "/^securitySecret/d" -i /var/lib/logitechmediaserver/preferences/server.prefs
	fi

	# 24-04-21 remove profile 21 obsolete merged-usr entries in make.conf
	if [ ${PROFILE} -ge 23 ]; then
		sed -e "s/\-split\-usr//" -e "s/^UNINSTALL_IGNORE/#UNINSTALL_IGNORE/" -i /etc/portage/make.conf
		[[ -e /etc/portage/package.use.force/merged-usr ]]  && rm -v /etc/portage/package.use.force/merged-usr
		[[ -d /etc/portage/package.use.force ]] && rmdir -v /etc/portage/package.use.force
	fi

	# 22-08-16 cleanup sakaki repositories as packages are throwing errors in emerge
	LOCALPORTAGE=${ROOT}/usr/local/portage
	if [[ -d ${LOCALPORTAGE}/gentoo-b3 ]]; then\
		rm -v -rf ${LOCALPORTAGE}/gentoo-b3
		rm -v -f ${ROOT}/etc/portage/repos.conf/gentoo-b3.conf
	fi
	if [[ -e ${LOCALPORTAGE}/sakaki-tools/.git ]]; then
		rm -v -rf ${LOCALPORTAGE}/sakaki-tools/{.git,.gitignore,acct-group,acct-user,app-admin,app-crypt,dev-java,dev-python,eclass,media-gfx,net-im,sys-apps,sys-fs}
		rm -v -rf ${LOCALPORTAGE}/sakaki-tools/app-portage/{emtee,mvn2ebuild,porthash,porthole}
		sed -e "s/yes/no/" -i ${ROOT}/etc/portage/repos.conf/gentoo-b3.conf -i ${ROOT}/etc/portage/repos.conf/sakaki-tools.conf
	fi

	# 22-08-16 upgrade remaining packages from sakaki repositories to EAPI 8
	if (grep -q "EAPI=\"*5" ${LOCALPORTAGE}/sakaki-tools/app-portage/genup/genup-1.0.28.ebuild ); then
		sed -e "s/^EAPI=.*$/EAPI=\"8\"/" \
		    -i ${LOCALPORTAGE}/sakaki-tools/app-portage/genup/genup-1.0.28.ebuild \
		    -i ${LOCALPORTAGE}/sakaki-tools/app-portage/showem/showem-1.0.3.ebuild
		grep -m1 "EAPI=\"*5" ${LOCALPORTAGE}/*/*/*/*.ebuild | while read match; do
		    rm ${match%:*}
		done
		patch -d ${LOCALPORTAGE} -p1 < ${FILESDIR}/sakaki-EAPI-upgrade.patch
	fi
}
