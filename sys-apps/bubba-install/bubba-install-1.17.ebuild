# Copyright 2023 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="7"

KEYWORDS="~arm"

DESCRIPTION="Installer for Bubbagen on the Excito B3 miniserver"
HOMEPAGE="https://github.com/gordonb3/bubbagen"
SRC_URI=""
LICENSE="GPL-3+"
SLOT="0"
IUSE="liveusb sysinit minimal"

# required by Portage, as we have no SRC_URI...
S="${WORKDIR}"

DEPEND="virtual/bubba"
RDEPEND="${DEPEND}"

pkg_preinst() {
	# remove install.ini if it was unchanged from the previous installation,
	# however do not touch it if we are installing the exact same file
	diff -q ${FILESDIR}/install.ini ${ROOT}/root/install.ini 2&>/dev/null && return
	diff -q ${ROOT}/usr/share/doc/${PN}*/install.ini ${ROOT}/root/install.ini 2&>/dev/null && rm -f ${ROOT}/root/install.ini 2>/dev/null
}

src_install() {
	exeinto "/opt/bubba/sbin"
	newexe "${FILESDIR}/install_on_sda-${PVR}.sh" "install_on_sda.sh"
	insinto /usr/share/doc/${PF}
	docompress -x /usr/share/doc/${PF}
	doins "${FILESDIR}/fstab-on-b3" "${FILESDIR}/install.ini"
}

fix_old_install_scripts_if_present() {
	if [[ -x ${ROOT}/root/install_on_sda.sh && ! -L ${ROOT}/root/install_on_sda.sh ]]; then
		ewarn "Replacing /root/install_on_sda.sh script with symlink..."
		rm -f "${ROOT}/root/install_on_sda.sh"
	fi
	if [ -x ${ROOT}/root/install_on_sda_gpt.sh ]; then
		rm -f "${ROOT}/root/install_on_sda_gpt.sh"
	fi
}

pkg_postinst() {
	fix_old_install_scripts_if_present

	if [ ! -x ${ROOT}/root/install_on_sda.sh ]; then
		ln -s "../opt/bubba/sbin/install_on_sda.sh" "${ROOT}/root/install_on_sda.sh"
	fi

	if [ -n $(readlink ${ROOT}/root/install_on_sda.sh | grep "^/") ]; then
		rm -f "${ROOT}/root/install_on_sda.sh"
		ln -s "../opt/bubba/sbin/install_on_sda.sh" "${ROOT}/root/install_on_sda.sh"
	fi

	if [ -n $(readlink ${ROOT}/root/install_on_sda.sh | grep "^../usr") ]; then
		rm -f "${ROOT}/root/install_on_sda.sh"
		ln -s "../opt/bubba/sbin/install_on_sda.sh" "${ROOT}/root/install_on_sda.sh"
	fi

	# Gentoo throws a QA warning when installing to folders that are not part
	# of their policy, but I really want these files to end up in /root
	cp -a ${ROOT}/usr/share/doc/${PF}/fstab-on-b3 ${ROOT}/root/
	[[ -f ${ROOT}/root/install.ini ]] || cp -a ${ROOT}/usr/share/doc/${PF}/install.ini ${ROOT}/root/

	local OPTS="FORCEINSTALL"

	if use minimal; then
		OPTS="${OPTS} minimal"
	fi

	if use liveusb; then
		OPTS="${OPTS} nowizard nobackup"
		/opt/bubba/sbin/bubba-restore-defaults.sh ${OPTS}
	fi

	if use sysinit; then
		/opt/bubba/sbin/bubba-restore-defaults.sh ${OPTS}
	fi
}

pkg_postrm() {
	rm -f ${ROOT}/root/install_on_sd*.sh 2>/dev/null
	rm -f ${ROOT}/root/fstab-on-b3 2>/dev/null
	diff -q ${FILESDIR}/install.ini ${ROOT}/root/install.ini 2&>/dev/null && rm -f ${ROOT}/root/install.ini 2>/dev/null
}
