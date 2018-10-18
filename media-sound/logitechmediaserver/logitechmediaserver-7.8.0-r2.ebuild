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

inherit eutils user subversion systemd


MY_PN="${PN/-bin}"
MY_SHORT_PV="${PV/.0}"
MY_PV="${PV/_*}"
MY_P_BUILD_NUM="${MY_PN}-${MY_PV}-${BUILD_NUM}"
MY_P="${MY_PN}-${MY_PV}"
S="${WORKDIR}/${MY_PN}-${PV}-noCPAN"

SRC_DIR="LogitechMediaServer_v${PV}"
SRC_URI="http://downloads.slimdevices.com/${SRC_DIR}/${MY_PN}-${PV}-noCPAN.tgz"
HOMEPAGE="http://www.mysqueezebox.com/download"
BUILD_NUM="1375965195"

KEYWORDS="~amd64 ~x86 ~arm"
DESCRIPTION="Logitech Media Server (streaming audio server)"
LICENSE="${PN}"
RESTRICT="bindist mirror"
SLOT="0"
IUSE="systemd"

# Installation dependencies.
DEPEND="
	!media-sound/squeezecenter
	!media-sound/squeezeboxserver
	app-arch/unzip
	dev-vcs/subversion
	dev-lang/nasm
	"

# Runtime dependencies.
RDEPEND="
	!prefix? ( >=sys-apps/baselayout-2.0.0 )
	!prefix? ( virtual/logger )
	dev-db/sqlite
	>=dev-lang/perl-5.8.8[ithreads]
	>=dev-perl/Data-UUID-1.202
	=dev-perl/Audio-Scan-0.930.0-r1
	=dev-perl/Class-XSAccessor-1.190.0
	=dev-perl/DBIx-Class-0.82.700
	=dev-perl/SQL-Abstract-1.780.0
	dev-perl/CGI
	dev-perl/Class-C3-XS
	dev-perl/DBD-SQLite
	dev-perl/DBI
	dev-perl/Digest-SHA1
	dev-perl/Encode-Detect
	dev-perl/EV
	dev-perl/HTML-Parser
	dev-perl/Image-Scale[gif,jpeg,png]
	dev-perl/IO-AIO
	dev-perl/IO-Interface
	dev-perl/JSON-XS
	dev-perl/Linux-Inotify2
	dev-perl/Sub-Name
	dev-perl/Template-Toolkit[gd]
	dev-perl/XML-Parser
	dev-perl/YAML-LibYAML
	"

# This is a binary package and contains prebuilt executable and library
# files. We need to identify those to suppress the QA warnings during
# installation.
QA_PREBUILT="
	opt/logitechmediaserver/Bin/i386-linux/flac
	opt/logitechmediaserver/Bin/i386-linux/mppdec
	opt/logitechmediaserver/Bin/i386-linux/wvunpack
	opt/logitechmediaserver/Bin/i386-linux/sls
	opt/logitechmediaserver/Bin/i386-linux/sox
	opt/logitechmediaserver/Bin/i386-linux/faad
	opt/logitechmediaserver/Bin/i386-linux/mac
	opt/logitechmediaserver/Bin/arm-linux/flac
	opt/logitechmediaserver/Bin/arm-linux/wvunpack
	opt/logitechmediaserver/Bin/arm-linux/sls
	opt/logitechmediaserver/Bin/arm-linux/sox
	opt/logitechmediaserver/Bin/arm-linux/faad
	opt/logitechmediaserver/Bin/arm-linux/mac
	opt/logitechmediaserver/Bin/powerpc-linux/flac
	opt/logitechmediaserver/Bin/powerpc-linux/wvunpack
	opt/logitechmediaserver/Bin/powerpc-linux/sox
	opt/logitechmediaserver/Bin/powerpc-linux/faad
	opt/logitechmediaserver/Bin/powerpc-linux/mac
	opt/logitechmediaserver/Bin/sparc-linux/mp42aac
	opt/logitechmediaserver/Bin/sparc-linux/alac
	opt/logitechmediaserver/Bin/sparc-linux/aac2wav
	opt/logitechmediaserver/Bin/sparc-linux/faad
"

QA_PRESTRIPPED="
	/opt/logitechmediaserver/CPAN/auto/MP3/Cut/Gapless/Gapless.so
	/opt/logitechmediaserver/CPAN/auto/Media/Scan/Scan.so
	/opt/logitechmediaserver/CPAN/auto/Locale/Hebrew/Hebrew.so
	/opt/logitechmediaserver/CPAN/auto/Font/FreeType/FreeType.so
"

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


src_unpack() {
	unpack ${PN}-${PV}-noCPAN.tgz
	local S="${WORKDIR}/CPAN.upstream"
	ESVN_REPO_URI="http://svn.slimdevices.com/repos/slim/${MY_SHORT_PV}/trunk/vendor/CPAN/"
	subversion_src_unpack
	# Should not happen because of dependency.
	if [ -f ${PORTDIR}/distfiles/Class-XSAccessor-1.19.tar.gz ]; then
		cp ${PORTDIR}/distfiles/Class-XSAccessor-1.19.tar.gz ${S}
	else
		wget -O ${S}/Class-XSAccessor-1.19.tar.gz http://distfiles.gentoo.org/distfiles/Class-XSAccessor-1.19.tar.gz || die "Unable to fetch required Class::XSAccessor module"
	fi
}


src_prepare() {

	# Apply patches to make LMS work on Gentoo.
	epatch "${FILESDIR}/${PN}-bin-${PV}-uuid-gentoo.patch"
	epatch "${FILESDIR}/${PN}-bin-${PV}-client-playlists-gentoo.patch"

	# Add some enhancement patches of my own.
	epatch "${FILESDIR}/${PN}-bin-${PV}-fix-transition-sample-rates2.patch"
	epatch "${FILESDIR}/${PN}-bin-${PV}-remove-softlink-target-check.patch"

	# Remove conflicting module
	rm ../CPAN.upstream/Compress-Raw-Zlib-2.033.tar.gz CPAN/Compress/Raw/Zlib.pm

	epatch "${FILESDIR}/${P}-perl-recent.patch"
	MY_PERL_VERSION=$(ls -1d /var/db/pkg/dev-lang/perl* | sed "s/^.*perl-//" | awk -F. '{print $1"."$2}')

	sed \
		-e "/build_module Compress-Raw-Zlib/c true" \
		-e "s/XSAccessor-1.05/XSAccessor-1.19/g" \
		-e "/RUN_TESTS=1/c RUN_TESTS=0" \
		-e "s/perl5.12[.1-9]*/perl/g" \
		-e "s/5.12[.1-9]*/${MY_PERL_VERSION}/g" \
		-e "s/^\s\(\s*build [^\$]\)/#\1/" \
		-e "/function build_all/c function build_all {\n    build Font::FreeType\n    build MP3::Cut::Gapless\n    build Media::Scan" \
		-e "/FLAGS=\"-fPIC/c FLAGS=\"-fPIC -w\"" \
		-e "/function build_module/cfunction build_module {\n    CFLAGS=\$FLAGS\n    echo \$CFLAGS" \
		-i ../CPAN.upstream/buildme.sh

	# Hebrew language component will cause a QA notice - skip it if not required
        if has he ${LINGUAS} || has he ${L10N}; then
                einfo "Enable building of Hebrew lang files"
		sed -e "/function build_all/c function build_all {\n    build Locale::Hebrew" \
		-i ../CPAN.upstream/buildme.sh
	fi

	# fix deprecation warning in Perl 2.4
	epatch "${FILESDIR}/perl-24.patch"
}

src_compile() {
        cd ../CPAN.upstream
        sh buildme.sh
        cd -
}



lms_clean_oldfiles() {
	MY_PERL_VENDORPATH=$(perl -V | grep vendorarch | sed "s/^.*vendorarch=//" | sed "s/ .*$//g")
	cd ${MY_PERL_VENDORPATH}
	find -type f | sed "s/^\.\///" | while read file; do 
		if [ -f ${ED}${BINDIR}/CPAN/${file} ]; then
			rm ${ED}${BINDIR}/CPAN/${file}
		fi
	done
	cd -

	# delete empty directories in LMS path
	cd ${ED}${BINDIR}
	MY_SEARCHDEPTH=5
	while [  ${MY_SEARCHDEPTH} -gt 0 ]; do
		find -mindepth ${MY_SEARCHDEPTH} -maxdepth ${MY_SEARCHDEPTH} -type d -empty -exec rmdir {} \;
		MY_SEARCHDEPTH=$((MY_SEARCHDEPTH-1))
	done
	cd -
}


src_install() {

	# The custom OS module for Gentoo - provides OS-specific path details
	cp "${FILESDIR}/gentoo-filepaths.pm-r2" "Slim/Utils/OS/Custom.pm" || die "Unable to install Gentoo custom OS module"

	# Everthing into our package in the /opt hierarchy (LHS)
	dodir "${BINDIR}"
	cp -aR "${S}"/* "${ED}${BINDIR}" || die "Unable to install package files"
	cp -aR "${S}"/../CPAN.upstream/build/5.*/lib/perl5/*linux*/* "${ED}${BINDIR}/CPAN" || die "Unable to install package files"

	# Delete files that also exist in Perl's vendor path
	# (possibly hazardous on broken perl installs, but required to fix version conflicts)
	lms_clean_oldfiles

	# As said: dangerous...
	#  - restore DBIx modules; the software specifically requires version 0.08112
	cp -aR "${S}"/CPAN/DBIx "${ED}${BINDIR}/CPAN/" || die "Unable to install package files"

	# Documentation
	dodoc Changelog*.html
	dodoc Installation.txt
	dodoc License*.txt
	dodoc "${FILESDIR}/Gentoo-plugins-README.txt"
	dodoc "${FILESDIR}/Gentoo-detailed-changelog.txt"

	# This may seem a weird construct, but it keeps me from getting QA messages on OpenRC systems
	if use systemd ; then
		# Install unit file (systemd)
		cat "${FILESDIR}/${MY_PN}.service-r2" | sed "s/^#Env/Env/" > "${S}/../${MY_PN}.service"
		systemd_dounit "${S}/../${MY_PN}.service"
	else
		# Install init script (OpenRC)
		newinitd "${FILESDIR}/logitechmediaserver.init.d-r2" "${MY_PN}"
	fi
	newconfd "${FILESDIR}/logitechmediaserver.conf.d" "${MY_PN}"


	# Data directory
	keepdir "${DATADIR}"
	fowners ${RUN_UID}:${RUN_GID} "${DATADIR}"
	fperms 770 "${DATADIR}"

	# Preferences directory
	keepdir "${PREFSDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${PREFSDIR}"
	fperms 770 "${PREFSDIR}"

	# Initialize server cache directory
	keepdir "${CACHEDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${CACHEDIR}"
	fperms 770 "${CACHEDIR}"

	# Initialize the log directory
	keepdir "${LOGDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}"
	fperms 770 "${LOGDIR}"
	touch "${ED}/${LOGDIR}/server.log"
	touch "${ED}/${LOGDIR}/scanner.log"
	touch "${ED}/${LOGDIR}/perfmon.log"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/server.log"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/scanner.log"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/perfmon.log"

	# Initialise the user-installed plugins directory
	keepdir "${USRPLUGINSDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${USRPLUGINSDIR}"
	fperms 770 "${USRPLUGINSDIR}"

	# Initialise the client playlists directory
	keepdir "${CLIENTPLAYLISTSDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${CLIENTPLAYLISTSDIR}"
	fperms 770 "${CLIENTPLAYLISTSDIR}"

	# Install logrotate support
	insinto /etc/logrotate.d
	newins "${FILESDIR}/logitechmediaserver.logrotate.d" "${MY_PN}"
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
