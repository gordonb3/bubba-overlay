# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
#
# Largely stolen from the squeezebox overlay and adapted to run on armv5
# with perl >= 5.18
# Unlike the squeezebox overlay version this is a source build and you
# are advised to use distcc when installing this on an armv5 device like
# Bubba 2|3.
#
# $Header$

EAPI="5"

inherit eutils user systemd

MY_PN="${PN/-bin}"
MY_SHORT_PV="${PV/.0}"
MY_PV="${PV/_*}"
MY_PP="_${PV/*_}"
MY_P_BUILD_NUM="${MY_PN}-${MY_PV}-${BUILD_NUM}"
MY_P="${MY_PN}-${MY_PV}"
S="${WORKDIR}/${MY_PN}-${MY_PV}-noCPAN"

SRC_DIR="LogitechMediaServer_v${MY_PV}"
SRC_URI="http://downloads.slimdevices.com/${SRC_DIR}/${MY_PN}-${MY_PV}-noCPAN.tgz
	https://github.com/gordonb3/${MY_PN}-cpan-armel/archive/${MY_PV}${MY_PP}.tar.gz -> ${PF}-CPAN-armel.tgz
"
HOMEPAGE="http://www.mysqueezebox.com/download"
BUILD_NUM="1375965195"

KEYWORDS="~arm"
DESCRIPTION="Logitech Media Server (streaming audio server)"
LICENSE="${MY_PN}"
RESTRICT="bindist mirror strip"
SLOT="0"
IUSE="systemd"

# Installation dependencies.
DEPEND="
	!media-sound/squeezecenter
	!media-sound/squeezeboxserver
	!media-sound/logitechmediaserver
	app-arch/unzip
	dev-lang/perl:=[ithreads]
	"

# Runtime dependencies.
RDEPEND="
	!prefix? ( >=sys-apps/baselayout-2.0.0 )
	!prefix? ( virtual/logger )
	dev-db/sqlite
	media-libs/giflib
	"

# This is a binary package and contains prebuilt executable and library
# files. We need to identify those to suppress the QA warnings during
# installation.
QA_PREBUILT="
	opt/${MY_PN}/Bin/arm-linux/flac
	opt/${MY_PN}/Bin/arm-linux/wvunpack
	opt/${MY_PN}/Bin/arm-linux/sls
	opt/${MY_PN}/Bin/arm-linux/sox
	opt/${MY_PN}/Bin/arm-linux/faad
	opt/${MY_PN}/Bin/arm-linux/mac
"

QA_PRESTRIPPED="opt/${MY_PN}/CPAN/arch/.*/auto/.*"
QA_TEXTRELS="opt/${MY_PN}/CPAN/arch/.*/auto/Media/Scan/Scan.so"



RUN_UID=logitechmediaserver
RUN_GID=logitechmediaserver

# Installation locations
BINDIR="/opt/${MY_PN}"
DATADIR="/var/lib/${MY_PN}"
CACHEDIR="${DATADIR}/cache"
USRPLUGINSDIR="${DATADIR}/Plugins"
SVRPLUGINSDIR="${CACHEDIR}/InstalledPlugins"
CLIENTPLAYLISTSDIR="${DATADIR}/ClientPlaylists"
PREFSDIR="${DATADIR}/preferences"
LOGDIR="/var/log/${MY_PN}"
SVRPREFS="${PREFSDIR}/server.prefs"

# Old Squeezebox Server file locations
SBS_PREFSDIR='/etc/squeezeboxserver/prefs'
SBS_SVRPREFS="${SBS_PREFSDIR}/server.prefs"
SBS_VARLIBDIR='/var/lib/squeezeboxserver'
SBS_SVRPLUGINSDIR="${SBS_VARLIBDIR}/cache/InstalledPlugins"
SBS_USRPLUGINSDIR="${SBS_VARLIBDIR}/Plugins"

# Original preferences location from the Squuezebox overlay
R1_PREFSDIR="/etc/${MY_PN}"


pkg_setup() {
	# Create the user and group if not already present
	enewgroup ${RUN_GID}
	enewuser ${RUN_UID} -1 -1 "/dev/null" ${RUN_GID}
}


src_install() {

	PERL_VER=$(echo "print \$^V" | perl | sed "s/v\(.\...\).*/\1/")

	# Everything into our package in the /opt hierarchy (LHS)
	dodir "${BINDIR}"
	cp -aR "${S}"/* "${ED}${BINDIR}" || die "Unable to install package files"

	# Documentation
	dodoc Changelog*.html
	dodoc Installation.txt
	dodoc License*.txt

	# Clean documentation from target install folder
	rm "${ED}${BINDIR}"/Changelog*.html
	rm "${ED}${BINDIR}"/Installation.txt
	rm "${ED}${BINDIR}"/License*.txt


	# change dir to CPAN binaries
	cd "${S}"/../"${MY_PN}"-cpan*

	# overwrite everything in Bin CPAN and Slim with our platform specific versions
	cp -aR Bin CPAN Slim "${ED}${BINDIR}" || die "Unable to install CPAN binaries"

	# The custom OS module for Gentoo - provides OS-specific path details
	cp -aR gentoo/Slim gentoo/slimserver.pl "${ED}${BINDIR}" || die "Unable to install Gentoo custom OS module"

	# Gentoo additional documentation
	dodoc "Gentoo-plugins-README.txt"


	if has he ${LINGUAS} || has he ${L10N}; then
		einfo "Keeping Hebrew lang files"
	else
		rm "${ED}${BINDIR}"/CPAN/Locale/Hebrew.pm
		rmdir --ignore-fail-on-non-empty "${ED}${BINDIR}"/CPAN/Locale
		rm -r "${ED}${BINDIR}"/CPAN/arch/*/*/auto/Locale/Hebrew
		rmdir --ignore-fail-on-non-empty "${ED}${BINDIR}"/CPAN/arch/*/*/auto/Locale
	fi


	# This may seem a weird construct, but it keeps me from getting QA messages on OpenRC systems
	if use systemd ; then
		# Install unit file (systemd)
		cat "gentoo/${MY_PN}.service" | sed "s/^#Env/Env/" > "${S}/../${MY_PN}.service"
		systemd_dounit "${S}/../${MY_PN}.service"
	else
		# Install init script (OpenRC)
		newinitd "gentoo/logitechmediaserver.init.d" "${MY_PN}"
	fi
	newconfd "gentoo/logitechmediaserver.conf.d" "${MY_PN}"

	# Install logrotate support
	insinto /etc/logrotate.d
	newins "gentoo/logitechmediaserver.logrotate.d" "${MY_PN}"

	cd -

	# Create data directory structure
	keepdir "${PREFSDIR}"
	keepdir "${CACHEDIR}"
	keepdir "${LOGDIR}"
	keepdir "${USRPLUGINSDIR}"
	keepdir "${CLIENTPLAYLISTSDIR}"
	fowners ${RUN_UID}:${RUN_GID} -R "${DATADIR}"
	fperms 0770 -R "${DATADIR}"

	# Replace the 5.24 modules with the PIE versions if we are on profile 17
	if [ "${PERL_VER}" == "5.24" ]; then
		if (gcc -march=native -E -v - </dev/null 2>&1 | grep -q "\-\-enable\-default\-pie"); then
			rm -r "${ED}${BINDIR}"/CPAN/arch/5.24
			mv "${ED}${BINDIR}"/CPAN/arch/5.24-pie "${ED}${BINDIR}"/CPAN/arch/5.24
		fi
	fi

	# Remove obsolete Perl modules
	ls -1 "${ED}${BINDIR}"/CPAN/arch | while read arch; do
		if [ "${arch}" != "${PERL_VER}" ]; then
			rm -r "${ED}${BINDIR}"/CPAN/arch/"${arch}"
		fi
	done

	# Compress is a core function since Perl 5.22
	if [ "${PERL_VER}" != "5.20" ]; then
		rm -r "${ED}${BINDIR}"/CPAN/Compress
	fi
}

lms_starting_instr() {
	elog "Logitech Media Server can be started with the following command:"
	if use systemd ; then
		elog "\tsystemctl start logitechmediaserver"
	else
		elog "\t/etc/init.d/logitechmediaserver start"
	fi
	elog ""
	elog "Logitech Media Server can be automatically started on each boot"
	elog "with the following command:"
	if use systemd ; then
		elog "\tsystemctl enable logitechmediaserver"
	else
		elog "\trc-update add logitechmediaserver default"
	fi
	elog ""
	elog "You might want to examine and modify the following configuration"
	elog "file before starting Logitech Media Server:"
	elog "\t/etc/conf.d/logitechmediaserver"
	elog ""

	# Discover the port number from the preferences, but if it isn't there
	# then report the standard one.
	httpport=$(gawk '$1 == "httpport:" { print $2 }' "${ROOT}${SVRPREFS}" 2>/dev/null)
	elog "You may access and configure Logitech Media Server by browsing to:"
	elog "\thttp://localhost:${httpport:-9000}/"
	elog ""
}

pkg_postinst() {

	# Point user to database configuration step, if an old installation
	# of SBS is found.
	if [ -f "${SBS_SVRPREFS}" ]; then
		elog "If this is a new installation of Logitech Media Server and you"
		elog "previously used Squeezebox Server (media-sound/squeezeboxserver)"
		elog "then you may migrate your previous preferences and plugins by"
		elog "running the following command (note that this will overwrite any"
		elog "current preferences and plugins):"
		elog "\temerge --config =${CATEGORY}/${PF}"
		elog ""
	fi

	# Tell use user where they should put any manually-installed plugins.
	elog "Manually installed plugins should be placed in the following"
	elog "directory:"
	elog "\t${USRPLUGINSDIR}"
	elog ""

	# Bug: LMS should not write to /etc
	# Move existing preferences from /etc to /var/lib
	if [ ! -f "${PREFSDIR}/server.prefs" ]; then
		if [ -d "${R1_PREFSDIR}" ]; then
			cp -r "${R1_PREFSDIR}"/* "${PREFSDIR}" || die "Failed to copy preferences"
			rm -r "${R1_PREFSDIR}"
			chown -R ${RUN_UID}.${RUN_GID} "${PREFSDIR}"
		fi
	fi

	# Show some instructions on starting and accessing the server.
	lms_starting_instr
}

lms_remove_db_prefs() {
	MY_PREFS=$1

	einfo "Correcting database connection configuration:"
	einfo "\t${MY_PREFS}"
	TMPPREFS="${T}"/lmsserver-prefs-$$
	touch "${EROOT}${MY_PREFS}"
	sed -e '/^dbusername:/d' -e '/^dbpassword:/d' -e '/^dbsource:/d' < "${EROOT}${MY_PREFS}" > "${TMPPREFS}"
	mv "${TMPPREFS}" "${EROOT}${MY_PREFS}"
	chown ${RUN_UID}:${RUN_GID} "${EROOT}${MY_PREFS}"
	chmod 660 "${EROOT}${MY_PREFS}"
}

pkg_config() {
	einfo "Press ENTER to migrate any preferences from a previous installation of"
	einfo "Squeezebox Server (media-sound/squeezeboxserver) to this installation"
	einfo "of Logitech Media Server."
	einfo ""
	einfo "Note that this will remove any current preferences and plugins and"
	einfo "therefore you should take a backup if you wish to preseve any files"
	einfo "from this current Logitech Media Server installation."
	einfo ""
	einfo "Alternatively, press Control-C to abort now..."
	read

	# Preferences.
	einfo "Migrating previous Squeezebox Server configuration:"
	if [ -f "${SBS_SVRPREFS}" ]; then
		[ -d "${EROOT}${PREFSDIR}" ] && rm -rf "${EROOT}${PREFSDIR}"
		einfo "\tPreferences (${SBS_PREFSDIR})"
		cp -r "${EROOT}${SBS_PREFSDIR}" "${EROOT}${PREFSDIR}"
		chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${PREFSDIR}"
		chmod -R u+w,g+w "${EROOT}${PREFSDIR}"
		chmod 770 "${EROOT}${PREFSDIR}"
	fi

	# Plugins installed through the built-in extension manager.
	if [ -d "${EROOT}${SBS_SVRPLUGINSDIR}" ]; then
		einfo "\tServer plugins (${SBS_SVRPLUGINSDIR})"
		[ -d "${EROOT}${SVRPLUGINSDIR}" ] && rm -rf "${EROOT}${SVRPLUGINSDIR}"
		cp -r "${EROOT}${SBS_SVRPLUGINSDIR}" "${EROOT}${SVRPLUGINSDIR}"
		chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${SVRPLUGINSDIR}"
		chmod -R u+w,g+w "${EROOT}${SVRPLUGINSDIR}"
		chmod 770 "${EROOT}${SVRPLUGINSDIR}"
	fi

	# Plugins manually installed by the user.
	if [ -d "${EROOT}${SBS_USRPLUGINSDIR}" ]; then
		einfo "\tUser plugins (${SBS_USRPLUGINSDIR})"
		[ -d "${EROOT}${USRPLUGINSDIR}" ] && rm -rf "${EROOT}${USRPLUGINSDIR}"
		cp -r "${EROOT}${SBS_USRPLUGINSDIR}" "${EROOT}${USRPLUGINSDIR}"
		chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${USRPLUGINSDIR}"
		chmod -R u+w,g+w "${EROOT}${USRPLUGINSDIR}"
		chmod 770 "${EROOT}${USRPLUGINSDIR}"
	fi

	# Remove the existing MySQL preferences from Squeezebox Server (if any).
	lms_remove_db_prefs "${SVRPREFS}"

	# Phew - all done. Give some tips on what to do now.
	einfo "Done."
	einfo ""
}
