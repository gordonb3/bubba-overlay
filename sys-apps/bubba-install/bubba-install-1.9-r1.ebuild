# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"

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

src_install() {
	exeinto "/usr/local/sbin"
	doexe "${FILESDIR}/install_on_sda.sh"
	insinto "/root"
	doins "${FILESDIR}/fstab-on-b3"

}

fix_old_install_scripts_if_present() {
	if [[ -x "${ROOT}/root/install_on_sda.sh" && ! -L "${ROOT}/root/install_on_sda.sh" ]]; then
		ewarn "Replacing /root/install_on_sda.sh script with symlink..."
		rm -f "${ROOT}/root/install_on_sda.sh"
		ln -s "${ROOT}/usr/local/sbin/install_on_sda.sh" "${ROOT}/root/install_on_sda.sh"
	fi
	if [ -x "${ROOT}/root/install_on_sda_gpt.sh" ]; then
		rm -f "${ROOT}/root/install_on_sda_gpt.sh"
	fi
}

pkg_postinst() {
	fix_old_install_scripts_if_present

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
	rm -f "${ROOT}/root/install_on_sd*.sh" 2>/dev/null
}
