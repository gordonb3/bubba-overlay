# Copyright 2024 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
#
# $Header$

EAPI="8"

inherit systemd perl-module


MY_PV="${PV/_*}"
MY_PF="${PN}-${MY_PV}"
S="${WORKDIR}/${MY_PF}-noCPAN"

SRC_URI="http://downloads.lms-community.org/LogitechMediaServer_v${MY_PV}/${MY_PF}-noCPAN.tgz"
HOMEPAGE="https://lyrion.org/"

KEYWORDS="~amd64 ~x86 ~arm ~ppc"
DESCRIPTION="Logitech Media Server (streaming audio server)"
LICENSE="${PN}"
RESTRICT="mirror"
SLOT="0"
IUSE="systemd mp3 alac wavpack flac ogg aac mac freetype l10n_he"

PATCHES=(
	"${FILESDIR}/LMS-8.0.0_remove_softlink_target_check.patch"
	"${FILESDIR}/LMS-8.2.0_move_client_playlist_path.patch"
)

BDEPEND="
	app-arch/unzip
	dev-lang/nasm
"

DEPEND="
	acct-user/${PN}
	acct-group/${PN}
	dev-lang/perl[perl_features_ithreads]
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

RUN_UID=${PN}
RUN_GID=${PN}

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


pkg_pretend() {
	if ! use perl_features_ithreads; then
		echo ""
		ewarn "LogitechMediaServer requires perl ithreads support. As of dev-lang/perl-5.38.2-r3"
		ewarn "this must be set globally in make.conf in the use-expand variable PERL_FEATURES"
		ewarn "It appears that you have not set this variable properly yet."
		echo ""
		die "Terminating now"
	fi
}


src_prepare() {
	default	

	# fix default user name to run as
	sed -e "s/squeezeboxserver/${RUN_UID}/" -i slimserver.pl

	# merge the secondary lib folder into CPAN, keeping track of the various locations
	# for CPAN modules possibly duplicated in system is hard enough already without it.
	elog "Merging lib and CPAN folders"
	cp -aR lib/* CPAN/
	rm -rf lib
	sed -e "/catdir(\$libPath,'lib'),/d" -i Slim/bootstrap.pm

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
		newinitd "${FILESDIR}/${PN}.init.d" "${PN}"
	fi
	newconfd "${FILESDIR}/${PN}.conf.d" "${PN}"

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
	newins "${FILESDIR}/${PN}.logrotate.d" "${PN}"
}

lms_starting_instr() {
	# Tell user where they should put any manually-installed plugins.
	elog "Manually installed plugins should be placed in the following"
	elog "directory:"
	elog "\t${EROOT}${USRPLUGINSDIR}"
	echo ""

	elog "You might want to examine and modify the following configuration"
	elog "file before starting Logitech Media Server:"
	elog "\t/etc/conf.d/${PN}"
	echo ""

	# Discover the port number from the preferences, but if it isn't there
	# then report the standard one.
	httpport=$(gawk '$1 == "httpport:" { print $2 }' "${ROOT}${SVRPREFS}" 2>/dev/null)
	elog "You may access and configure Logitech Media Server by browsing to:"
	elog "\thttp://localhost:${httpport:-9000}/"
	echo ""

	elog "Privacy note: as of version 8.5.1 Logitech Media Server includes an analytic"
	elog "reporting plugin to aid developers in identifying elements for which support"
	elog "may be dropped. If you do not like to participate you can disable this plugin"
	elog "in the LMS Server Settings"
	echo ""
}

pkg_postinst() {
	# Use of DynaLoader causes conflicts because it prefers the system perl folders over the local CPAN folder.
	elog "Recursively wiping modules already present in system vendorarch path to prevent version conflicts."
	lms_wipe_duplicates
	echo ""

	# Bug: LMS should not write to /etc
	# Move existing preferences from /etc to /var/lib
	if [ ! -f "${EROOT}${PREFSDIR}/server.prefs" ]; then
		if [ -d "${EROOT}${R1_PREFSDIR}" ]; then
			cp -r "${EROOT}${R1_PREFSDIR}"/* "${EROOT}${PREFSDIR}" || die "Failed to copy preferences"
			rm -r "${EROOT}${R1_PREFSDIR}"
			chown -R ${RUN_UID}.${RUN_GID} "${EROOT}${PREFSDIR}"
		fi
	fi

	# Show some instructions on starting and accessing the server.
	lms_starting_instr
}

lms_wipe_duplicates() {
	MY_PERL_VENDOR_LIBPATH=$(LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" perl -V | grep vendorlib | sed -e "s/^.*vendorlib=//" -e "s/ .*$//g")
	cd ${MY_PERL_VENDOR_LIBPATH}
	find -type f | sed "s/^\.\///" | grep -v "/DBIx/" | while read file; do 
		if [ -f ${EROOT}${BINDIR}/CPAN/${file} ]; then
			rm ${EROOT}${BINDIR}/CPAN/${file}
		fi
	done
	cd - &>/dev/null

	MY_PERL_VENDOR_ARCHPATH=$(LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" perl -V | grep vendorarch | sed -e "s/^.*vendorarch=//" -e "s/ .*$//g")
	cd ${MY_PERL_VENDOR_ARCHPATH}
	find -type f | sed "s/^\.\///" | grep -v "/DBIx/" | while read file; do 
		if [ -f ${EROOT}${BINDIR}/CPAN/${file} ]; then
			rm ${EROOT}${BINDIR}/CPAN/${file}
		fi
	done
	cd - &>/dev/null

	# remove empty directories in LMS path
	cd ${EROOT}${BINDIR}
	MY_SEARCHDEPTH=5
	while [  ${MY_SEARCHDEPTH} -gt 0 ]; do
		find -mindepth ${MY_SEARCHDEPTH} -maxdepth ${MY_SEARCHDEPTH} -type d -empty -exec rmdir {} \;
		MY_SEARCHDEPTH=$((MY_SEARCHDEPTH-1))
	done
	cd - &>/dev/null
}

