# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

# Although this is a git source, the project appears to be static, 
# so there's no sense in rechecking the source with every reinstall.
#EGIT_REPO_URI="git://github.com/tamlyn/singapore.git"
COMMIT="8524ace0fcae7e144aea803ad0261c31b97b3033"

MY_PV=${PV/_*/}
SRC_URI="https://github.com/tamlyn/singapore/archive/${COMMIT}.zip -> ${PN}-${MY_PV}.zip"
RESTRICT="mirror"

DESCRIPTION="Singapore Image Gallery"
HOMEPAGE="http://www.sgal.org"
SLOT="0"
LICENSE="GPL-3"
KEYWORDS="~arm ~ppc"
IUSE="+apache"

DEPEND=""

RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}/bubba.patch"
	  "${FILESDIR}/php5.6.patch"
	  "${FILESDIR}/php8.patch"
)

S=${WORKDIR}/${PN}-${COMMIT}


src_prepare() {
	eapply_user

	sed -i "s/\r//" ${S}/includes/singapore.class.php
	
	default
}

src_install() {
	docompress -x /usr/share/doc/${PF}
	dodoc Readme.txt ${FILESDIR}/apache.confd
	newdoc singapore.ini singapore.ini.default
	if getent passwd admin >/dev/null; then
		fowners admin.users /usr/share/doc/${PF}/singapore.ini.default
		fperms 0664 /usr/share/doc/${PF}/singapore.ini.default
	fi

	insinto /opt/${PN}/htdocs
	doins -r *.php data docs includes locale templates tools


	insinto /home/web/photos
	if use apache; then
		fowners apache.users /home/web/photos
	else
		fowners root.users /home/web/photos
	fi
	fperms 2775 /home/web/photos

	touch ${ED}/home/web/photos/.singapore_keep_this_dir

	doins singapore.ini
	fowners admin.users /home/web/photos/singapore.ini
	fperms 0664 /home/web/photos/singapore.ini


	dosym /home/web/photos /opt/${PN}/photos 
	dosym /home/web/photos/singapore.ini /opt/${PN}/htdocs/singapore.ini

}
