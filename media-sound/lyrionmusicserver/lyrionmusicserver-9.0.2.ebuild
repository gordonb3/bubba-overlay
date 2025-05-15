# Copyright 2024 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
#
# $Header$

EAPI="8"

inherit systemd


MY_PV="${PV/_*}"
MY_PF="${PN}-${MY_PV}"
S="${WORKDIR}/${MY_PF}-noCPAN"

SRC_URI="http://downloads.lms-community.org/LyrionMusicServer_v${MY_PV}/${MY_PF}-noCPAN.tgz"
HOMEPAGE="https://lyrion.org/"

KEYWORDS="~amd64 ~x86 ~arm ~ppc"
DESCRIPTION="Lyrion Music Server (streaming audio server)"
LICENSE="GPL-3"
RESTRICT="mirror"
SLOT="0"
IUSE="systemd mp3 alac wavpack flac ogg aac mac freetype l10n_he perl_features_ithreads"

RUN_UID="lyrion"
RUN_GID=${RUN_UID}

# Installation target locations
BINDIR="/opt/${PN}"
DATADIR="/var/lib/${PN}"
CACHEDIR="${DATADIR}/cache"
USRPLUGINSDIR="${DATADIR}/Plugins"
SVRPLUGINSDIR="${CACHEDIR}/InstalledPlugins"
CLIENTPLAYLISTSDIR="${DATADIR}/ClientPlaylists"
PREFSDIR="${DATADIR}/preferences"
LOGDIR="/var/log/${PN}"
SVRPREFS="${PREFSDIR}/server.prefs"

# Old Logitech Media Server file locations
OLD_UID="logitechmediaserver"
OLD_GID=${OLD_UID}
SBS_DATADIR="/var/lib/${OLD_UID}"
SBS_USRPLUGINSDIR="${SBS_DATADIR}/Plugins"
SBS_SVRPLUGINSDIR="${SBS_DATADIR}/cache/InstalledPlugins"
SBS_PREFSDIR="${SBS_DATADIR}/preferences"
SBS_SVRPREFS="${SBS_PREFSDIR}/server.prefs"

PATCHES=(
	"${FILESDIR}/LMS-8.0.0_remove_softlink_target_check.patch"
	"${FILESDIR}/LMS-8.2.0_move_client_playlist_path.patch"
)

BDEPEND="
	app-arch/unzip
	dev-lang/nasm
"

DEPEND="
	acct-user/${RUN_UID}
	acct-group/${RUN_GID}
	>=dev-lang/perl-5.38.2-r3[perl_features_ithreads]
	dev-perl/Audio-Scan
	dev-perl/Class-XSAccessor
	dev-perl/DBD-SQLite
	dev-perl/Digest-SHA1
	dev-perl/EV
	dev-perl/Encode-Detect
	dev-perl/HTML-Parser
	dev-perl/IO-AIO
	dev-perl/IO-Interface
	dev-perl/Image-Scale[gif,jpeg,png]
	dev-perl/JSON-XS
	dev-perl/Linux-Inotify2
	dev-perl/MP3-Cut-Gapless
	dev-perl/Sub-Name
	dev-perl/Template-Toolkit[gd]
	dev-perl/XML-Parser
	dev-perl/YAML-LibYAML
	freetype? ( dev-perl/Font-FreeType )
	l10n_he? ( dev-perl/Locale-Hebrew )
	dev-perl/Carp-Assert
"

RDEPEND="
	${DEPEND}
	virtual/logger
	mp3? ( media-sound/lame )
	wavpack? ( media-sound/wavpack )
	flac? (
		media-libs/flac
		media-sound/sox[flac]
	)
	ogg? ( media-sound/sox[ogg] )
	aac? ( media-libs/slim-faad )
	alac? ( media-libs/slim-faad )
	mac? ( media-sound/mac )
"

pkg_pretend() {
	if ! use perl_features_ithreads; then
		echo ""
		ewarn "LyrionMusicServer requires perl ithreads support. As of dev-lang/perl-5.38.2-r3"
		ewarn "this must be set globally in make.conf in the use-expand variable PERL_FEATURES"
		ewarn "It appears that you have not set this variable properly yet."
		echo ""
		die "Terminating now"
	fi
}

src_prepare() {
	default	

	# fix default user name to run as
	sed -e "s/nobody/${RUN_UID}/" -i slimserver.pl

	# merge the secondary lib folder into CPAN, keeping track of the various locations
	# for CPAN modules possibly duplicated in system is hard enough already without it.
	elog "Merging lib and CPAN folders"
	cp -aR lib/* CPAN/
	rm -rf lib
	sed -e "/catdir(\$libPath,'lib'),/d" -i Slim/bootstrap.pm

	# Locale::Hebrew is provided by dev-perl/Locale-Hebrew
	rm CPAN/Locale/Hebrew.pm

	# upstream should really upgrade their version
	rm CPAN/Carp/Assert.pm
}

src_install() {
	# Everything in our package into the /opt hierarchy
	elog "Installing package files"
	dodir "${BINDIR}"
	cp -aR ${S}/* "${ED}/${BINDIR}" || die "Unable to install package files"
	rm ${ED}/${BINDIR}/{Changelog*,License*,README.md,SOCKS.txt}

	# The custom OS module for Gentoo - provides OS-specific path details
	elog "Import custom paths to match Gentoo specifications"
	cp "${FILESDIR}/gentoo-filepaths.pm" "${ED}/${BINDIR}/Slim/Utils/OS/Custom.pm" || die "Unable to install Gentoo custom OS module"
	fperms 644 "${BINDIR}/Slim/Utils/OS/Custom.pm"

	# Documentation
	dodoc Changelog*.html
	dodoc License*.txt
	dodoc "${FILESDIR}/Gentoo-plugins-README.txt"

	if use systemd ; then
		# Install unit file (systemd)
		systemd_dounit "${FILESDIR}/${PN}.service"
	else
		# Install init script (OpenRC)
		newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	fi
	newconfd "${FILESDIR}/${PN}.conf" "${PN}"

	# prepare data and log file locations
	elog "Set up log and data file locations"
	for TARGETDIR in ${LOGDIR} ${DATADIR} ${PREFSDIR} ${CACHEDIR} ${USRPLUGINSDIR} ${CLIENTPLAYLISTSDIR}; do
		keepdir ${TARGETDIR}
		fowners ${RUN_UID}:${RUN_GID} "${TARGETDIR}"
		fperms 770 "${TARGETDIR}"
	done
	for LOGFILE in server scanner perfmon; do
		touch "${ED}/${LOGDIR}/${LOGFILE}.log"
		fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/${LOGFILE}.log"
	done

	# Install logrotate support
	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"
}

pkg_postinst() {
	# Use of DynaLoader causes version conflicts because it prefers the system perl folders over the local CPAN folder.
	elog "Recursively wiping modules already present in system vendorarch path to prevent version conflicts."
	MY_PERL_VENDOR_ARCHPATH=$(LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" perl -V | grep vendorarch | sed -e "s/^.*vendorarch=//" -e "s/ .*$//g")
	cd ${MY_PERL_VENDOR_ARCHPATH}
	find -type f | sed "s/^\.\///" | grep -v "/DBIx/" | while read file; do 
		if [ -f "${EROOT}${BINDIR}/CPAN/${file}" ]; then
			rm ${EROOT}${BINDIR}/CPAN/${file}
		fi
	done
	cd - &>/dev/null

	# remove empty directories in LMS path.
	cd ${EROOT}${BINDIR}
	MY_SEARCHDEPTH=5
	while [ ${MY_SEARCHDEPTH} -gt 0 ]; do
		find -mindepth ${MY_SEARCHDEPTH} -maxdepth ${MY_SEARCHDEPTH} -type d -empty -exec rmdir {} \;
		MY_SEARCHDEPTH=$((MY_SEARCHDEPTH-1))
	done
	cd - &>/dev/null
	echo ""

	# Preferences.
	if [ ! -f "${EROOT}${SVRPREFS}" ]; then
		if [ -f "${EROOT}${SBS_SVRPREFS}" ]; then
			einfo "Migrating previous Logitech Media Server configuration:"
			cp -r "${EROOT}${SBS_SVRPREFS}" "${EROOT}${PREFSDIR}"
			cp -r "${EROOT}${SBS_PREFSDIR}/favorites.opml" "${EROOT}${PREFSDIR}"
			cp -r "${EROOT}${SBS_PREFSDIR}/log.conf" "${EROOT}${PREFSDIR}"
			cp -r "${EROOT}${SBS_SVRPLUGINSDIR}" "${EROOT}${SVRPLUGINSDIR}" 2>/dev/null
			cp -r "${EROOT}${SBS_USRPLUGINSDIR}" "${EROOT}${USRPLUGINSDIR}" 2>/dev/null
			mkdir -p "${EROOT}${PREFSDIR}/plugin"
			sed -e "s/logitechmediaserver/lyrionmusicserver/" -i "${EROOT}${SVRPREFS}"
			chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${DATADIR}"
			chmod -R u+w,g+w "${EROOT}${DATADIR}"
			chmod -R o-rwx "${EROOT}${DATADIR}"

			if [ -f "/etc/bubba/bubba.version" ]; then
				einfo "Changing owner on files owned by ${OLD_UID}"
				einfo "(this may take a long time if you have a lot of music files)"
				find /home/storage/music -user ${OLD_UID} -exec chown ${RUN_UID} {} \;
				find /home/storage/music -group ${OLD_GID} -exec chgrp ${RUN_GID} {} \;
				if $(getfacl -p /home/storage/music | grep -q ":${OLD_UID}:"); then
					getfacl -p /home/storage > ${T}/aclentries
					getfacl -p -R /home/storage/music >> ${T}/aclentries
					sed -e "s/:${OLD_UID}:/:${RUN_UID}:/" -i ${T}/aclentries
					setfacl --restore=${T}/aclentries
				fi
			else
				ewarn "Due to Lyrion Music Server no longer belonging to the Logitech brand the user"
				ewarn "name it runs under has also be changed from '${OLD_UID}' to"
				ewarn "'${RUN_UID}'."
				ewarn "You should thus verify that the new user '${RUN_UID}' has access to your music"
				ewarn "files before starting Lyrion Music Server or your music library will turn up"
				ewarn "being empty."
			fi
		fi
	fi

	if [ -L /etc/runlevels/default/${OLD_UID} ]; then
		rc-update del ${OLD_UID}
		rc-update add ${PN}
	fi

	# Show some instructions on starting and accessing the server.
	# Tell user where they should put any manually-installed plugins.
	elog "Manually installed plugins should be placed in the following"
	elog "directory:"
	elog "\t${EROOT}${USRPLUGINSDIR}"
	echo ""

	elog "You might want to examine and modify the following configuration"
	elog "file before starting Lyrion Music Server:"
	elog "\t/etc/conf.d/${PN}"
	echo ""

	# Discover the port number from the preferences, but if it isn't there
	# then report the standard one.
	httpport=$(gawk '$1 == "httpport:" { print $2 }' "${ROOT}${SVRPREFS}" 2>/dev/null)
	elog "You may access and configure Lyrion Music Server by browsing to:"
	elog "\thttp://localhost:${httpport:-9000}/"
	echo ""

	if [ ! -e "${ROOT}${PREFSDIR}/plugin/state.prefs" ] || (grep -q "Analytics:.*enabled" "${ROOT}${PREFSDIR}/plugin/state.prefs") ; then
		elog "Privacy note: Lyrion Music Server includes an analytic reporting plugin to aid"
		elog "developers in identifying elements for which support may be dropped. If you do"
		elog "not like to participate you can disable this plugin in the LMS Server Settings"
		echo ""
	fi
}

