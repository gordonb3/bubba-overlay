# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="6"
SLOT="6"


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
DEB_VERSION="6b38-1.13.10-1~deb7u1"
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
IUSE="alsa cups doc +fontconfig headless-awt javafx nsplugin pax_kernel selinux source"
REQUIRED_USE="javafx? ( alsa fontconfig )"

RESTRICT="mirror"
QA_PREBUILT="*"

# NOTES:
#
# * cups is dlopened.
#
# * libpng is also dlopened but only by libsplashscreen, which isn't
#   important, so we can exclude that.
#
#
RDEPEND="
	!headless-awt? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXtst
	)
	javafx? (
		dev-libs/glib:2
		dev-libs/libxml2:2
		dev-libs/libxslt
		media-libs/freetype:2
		x11-libs/cairo
		x11-libs/gtk+:2
		x11-libs/libX11
		x11-libs/libXtst
		x11-libs/libXxf86vm
		x11-libs/pango
		virtual/opengl
	)
	alsa? ( media-libs/alsa-lib )
	cups? ( net-print/cups )
	doc? ( dev-java/java-sdk-docs:${SLOT} )
	fontconfig? ( media-libs/fontconfig:1.0 )
	!prefix? ( sys-libs/glibc:* )
	selinux? ( sec-policy/selinux-java )"

# A PaX header isn't created by scanelf so depend on paxctl to avoid
# fallback marking. See bug #427642.
DEPEND="app-arch/zip
	pax_kernel? ( sys-apps/paxctl )"


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
	eapply_user

	cd usr/lib/jvm/java-${SLOT}-openjdk-${DEB_ARCH}

	if ! use alsa; then
		rm -v jre/lib/$(get_system_arch)/libjsoundalsa.* || die
	fi

	if use headless-awt; then
		rm -vr jre/lib/$(get_system_arch)/{xawt,libsplashscreen.*} \
		   {,jre/}bin/policytool bin/appletviewer || die
	fi

	echo "dereference links to ${MY_PN}-${SLOT}-jre-lib_${DEB_VERSION}_all"
	find -type l | while read link; do
		readlink $link | grep -q "openjdk-common/" && rm $link
	done
	cp -a ../java-${SLOT}-openjdk-common/* .

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
			rm $file 
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


	dodoc ${S}/usr/share/doc/openjdk-6-jdk/*

	# Both icedtea itself and the icedtea ebuild set PAX markings but we
	# disable them for the icedtea-bin build because the line below will
	# respect end-user settings when icedtea-bin is actually installed.
	java-vm_set-pax-markings "${ddest}"

	set_java_env
	java-vm_revdep-mask "${dest}"
	java-vm_sandbox-predict /proc/self/coredump_filter

}

pkg_postinst() {
	java-vm-2_pkg_postinst

	if ! use headless-awt && ! use javafx; then
		ewarn "You have disabled the javafx flag. Some modern desktop Java applications"
		ewarn "require this and they may fail with a confusing error message."
	fi
}
