# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"
SLOT="7"


inherit eutils java-vm-2 prefix versionator


MY_PN=${PN/-*/}

if [[ "$(get_version_component_range 4)" == 0 ]] ; then
	S_PV="$(get_version_component_range 1-3)"
else
	MY_PV_EXT="u$(get_version_component_range 4)"
	S_PV="$(get_version_component_range 1-4)"
fi

MY_PV="$(get_version_component_range 2)${MY_PV_EXT}"

AT_arm="ejdk-${MY_PV}-linux-arm-sflt.tar.gz"

DEB_DIST="http://security.debian.org/debian-security/pool/updates/main/o/"
DEB_VERSION="7u95-2.6.4-1~deb8u1"
DEB_PKGS=( jre-headless jre jdk )
DEB_ARCH="armel" 

DESCRIPTION="Debian precompile Java SE Development Kit"
HOMEPAGE="http://openjdk.java.net/"

SRC_URI="${DEB_DIST}/${MY_PN}-${SLOT}/${MY_PN}-${SLOT}-jre-lib_${DEB_VERSION}_all.deb"
for pkg in "${DEB_PKGS[@]}"; do
	SRC_URI+="
		${DEB_DIST}/${MY_PN}-${SLOT}/${MY_PN}-${SLOT}-${pkg}_${DEB_VERSION}_${DEB_ARCH}.deb
	"
done

LICENSE="GPL-2-with-linking-exception"
KEYWORDS="~arm"
IUSE="+alsa cjk +cups +gtk headless-awt nsplugin nss pulseaudio selinux +webstart"
REQUIRED_USE="gtk? ( !headless-awt ) nsplugin? ( !headless-awt )"

RESTRICT="preserve-libs strip mirror"
QA_PREBUILT="opt/.*"

# NOTES:
#
# * cups is dlopened.
#
# * libpng is also dlopened but only by libsplashscreen, which isn't
#   important, so we can exclude that.
#
#
RDEPEND=">=dev-libs/glib-2.42:2
	>=dev-libs/nss-3.16.1-r1
	>=dev-libs/nspr-4.10
	>=gnome-base/gsettings-desktop-schemas-3.12.2
	media-fonts/dejavu
	>=media-libs/fontconfig-2.11:1.0
	>=media-libs/freetype-2.5.5:2
	>=media-libs/lcms-2.6:2
	>=sys-devel/gcc-4.9.3
	>=sys-libs/glibc-2.22
	>=sys-libs/zlib-1.2.8-r1
	virtual/jpeg:62
	alsa? ( >=media-libs/alsa-lib-1.0 )
	!headless-awt? (
		>=media-libs/giflib-4.1.6-r1
		media-libs/libpng:0/16
		>=x11-libs/libX11-1.6
		>=x11-libs/libXcomposite-0.4
		>=x11-libs/libXext-1.3
		>=x11-libs/libXi-1.7
		>=x11-libs/libXrender-0.9.8
		>=x11-libs/libXtst-1.2
	)
	cjk? (
		media-fonts/arphicfonts
		media-fonts/baekmuk-fonts
		media-fonts/lklug
		media-fonts/lohit-fonts
		media-fonts/sazanami
	)
	cups? ( >=net-print/cups-2.0 )
	gtk? (
		>=dev-libs/atk-2.16.0
		>=x11-libs/cairo-1.14.2
		x11-libs/gdk-pixbuf:2
		>=x11-libs/gtk+-2.24:2
		>=x11-libs/pango-1.36
	)
	selinux? ( sec-policy/selinux-java )"

DEPEND="!arm? ( dev-util/patchelf )"

PDEPEND="webstart? ( dev-java/icedtea-web:0[icedtea7(+)] )
	nsplugin? ( dev-java/icedtea-web:0[icedtea7(+),nsplugin] )
	pulseaudio? ( dev-java/icedtea-sound )"


S="${WORKDIR}/openjdk"

src_unpack() {
	mkdir -p ${S} || die
	cd ${S}
	pkg="jre-lib"
	ar x ${DISTDIR}/${MY_PN}-${SLOT}-${pkg}_${DEB_VERSION}_all.deb
	ls -1 data.t* | while read file; do mv $file ${pkg}-$file; done
	unpack ./${pkg}-data.t*
	rm ${pkg}-data.t* control.t*
	for pkg in "${DEB_PKGS[@]}"; do
		ar x ${DISTDIR}/${MY_PN}-${SLOT}-${pkg}_${DEB_VERSION}_${DEB_ARCH}.deb
		ls -1 data.t* | while read file; do mv $file ${pkg}-$file; done
		unpack ./${pkg}-data.t*
		rm ${pkg}-data.t* control.t*
	done
}

src_prepare() {
	cd usr/lib/jvm/java-${SLOT}-openjdk-${DEB_ARCH}

	if ! use alsa; then
		rm -v jre/lib/$(get_system_arch)/libjsoundalsa.* || die
	fi

	if use headless-awt; then
		rm -vr jre/lib/$(get_system_arch)/{xawt,libsplashscreen.*} \
		   {,jre/}bin/policytool bin/appletviewer || die
	fi

	if ! use gtk; then
		rm -v jre/lib/$(get_system_arch)/libjavagtk.* || die
	fi

	if [ -d ../java-${SLOT}-openjdk-common ]; then
		echo "dereference links to ${MY_PN}-${SLOT}-jre-lib_${DEB_VERSION}_all"
		find -type l | while read link; do
			readlink $link | grep -q "openjdk-common/" && rm $link
		done
		cp -a ../java-${SLOT}-openjdk-common/* .
	fi

	echo "move links from /etc/java-${SLOT}-openjdk/ to /opt/${P}/etc/"
	cp -a ${S}/etc/java-${SLOT}-openjdk etc
	find -type l | while read link; do 
		if $(readlink $link | grep -q "^/etc/java"); then
			target=$(readlink $link | sed "s/\/etc\/java-${SLOT}-openjdk/etc/")
			depth=$(echo $link | awk -F "/" '{print NF-2}')
			linkpath=""
			while [ $depth != 0 ]; do
				linkpath=${linkpath}"../"
				depth=$(($depth-1))
			done
			rm $link && ln -s ${linkpath}${target} $link
		fi
	done

	rm -r ${S}/usr/share/doc/openjdk-${SLOT}-jdk/test-armel

	echo "remove broken links"
	find -type l | while read file; do 
		if [ ! -e $file ]; then
			rm -v $file 
		fi
	done

	cd -
}

src_install() {
	cd usr/lib/jvm/java-${SLOT}-openjdk-${DEB_ARCH}

	local dest="/opt/${P}"
	local ddest="${ED}${dest#/}"


	dodir "${dest}"

	# doins doesn't preserve executable bits.
	cp -pRP bin include jre lib man etc "${ddest}" || die


	dodoc ${S}/usr/share/doc/openjdk-${SLOT}-jdk/*

	if use webstart || use nsplugin; then
		dosym /usr/libexec/icedtea-web/itweb-settings "${dest}/bin/itweb-settings"
		dosym /usr/libexec/icedtea-web/itweb-settings "${dest}/jre/bin/itweb-settings"
	fi
	if use webstart; then
		dosym /usr/libexec/icedtea-web/javaws "${dest}/bin/javaws"
		dosym /usr/libexec/icedtea-web/javaws "${dest}/jre/bin/javaws"
	fi

	# Both icedtea itself and the icedtea ebuild set PAX markings but we
	# disable them for the icedtea-bin build because the line below will
	# respect end-user settings when icedtea-bin is actually installed.
	java-vm_set-pax-markings "${ddest}"

	set_java_env
	java-vm_revdep-mask "${dest}"
	java-vm_sandbox-predict /proc/self/coredump_filter

}

pkg_postinst() {
	if use nsplugin; then
		if [[ -n ${REPLACING_VERSIONS} ]] && ! version_is_at_least 7.2.4.3 ${REPLACING_VERSIONS} ]]; then
			elog "The nsplugin for icedtea-bin is now provided by the icedtea-web package"
			elog "If you had icedtea-bin-7 nsplugin selected, you may see a related error below"
			elog "The switch should complete properly during the subsequent installation of icedtea-web"
			elog "Afterwards you may verify the output of 'eselect java-nsplugin list' and adjust accordingly'"
		fi
	fi

	# Set as default VM if none exists
	java-vm-2_pkg_postinst
}
