# Copyright 2015-2021 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

SLOT="8"

inherit java-vm-2 prefix


MY_PN=${PN/-*/}

DEB_DIST="http://ftp.nl.debian.org/debian/pool/main/o"
DEB_VERSION="8u252-b09-1~deb9u1"
DEB_PKGS=( jre-headless jdk-headless )
DEB_ARCH="armel" 

DESCRIPTION="Debian precompile Java SE Development Kit"
HOMEPAGE="http://openjdk.java.net/"

for pkg in "${DEB_PKGS[@]}"; do
	SRC_URI+="
		${DEB_DIST}/${MY_PN}-${SLOT}/${MY_PN}-${SLOT}-${pkg}_${DEB_VERSION}_${DEB_ARCH}.deb
	"
done

LICENSE="GPL-2-with-linking-exception"
KEYWORDS="~arm"
IUSE=""
REQUIRED_USE=""

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
	sys-apps/pcsc-lite
	x11-base/xorg-proto
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
"

DEPEND="!arm? ( dev-util/patchelf )"

PDEPEND=""


S="${WORKDIR}/openjdk"

src_unpack() {
	mkdir -p ${S} || die
	cd ${S}
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

	rm -rf ${S}/usr/share/doc/openjdk-${SLOT}-jdk*/test-armel

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
	local ddest="${ED}${dest}"


	dodir "${dest}"

	# doins doesn't preserve executable bits.
	cp -pRP bin include jre lib man etc "${ddest}" || die


	dodoc ${S}/usr/share/doc/openjdk-${SLOT}-jdk*/*
	docompress -x /usr/share/doc/${PF}
	
	# Both icedtea itself and the icedtea ebuild set PAX markings but we
	# disable them for the icedtea-bin build because the line below will
	# respect end-user settings when icedtea-bin is actually installed.
	java-vm_set-pax-markings "${ddest}"

	set_java_env
	java-vm_revdep-mask "${dest}"
	java-vm_sandbox-predict /proc/self/coredump_filter

}

pkg_postinst() {
	# Set as default VM if none exists
	java-vm-2_pkg_postinst
}
