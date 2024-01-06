# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR=AGRUNDMA
# Note: 1.08 is an unofficial release by the Logitech Media Server community, so we are grabbing 1.01 and patch it to reach 1.08
DIST_VERSION=1.01
inherit perl-module

DESCRIPTION="Fast C metadata and tag reader for all common audio file formats"
# License note: ambiguity: https://rt.cpan.org/Ticket/Display.html?id=132450
LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x86-solaris ~arm ~ppc"
IUSE="test"
RESTRICT="!test? ( test )"

BDEPEND="
	virtual/perl-ExtUtils-MakeMaker
	test? (
		dev-perl/Test-Warn
	)
"
PERL_RM_FILES=(
	"t/02pod.t"
	"t/03podcoverage.t"
	"t/04critic.t"
)

PATCHES=( "${FILESDIR}/1.01_gentoo_fix_compiler_warnings.patch"
	  "${FILESDIR}/1.02_fix_opus_duration_bug.patch"
	  "${FILESDIR}/1.04_allow_seek_in_mp4_files_with_32bit_sample_rates.patch"
	  "${FILESDIR}/1.05_correct_id3_v2.4_extended_header_handling.patch"
	  "${FILESDIR}/1.06_handle_large_comment_headers_in_opus_files.patch"
	  "${FILESDIR}/1.07_ogg_opus_improve_seek.patch"
	  "${FILESDIR}/1.08_improve_mp4_tiny_atom_handling.patch"
)


src_compile() {
	mymake=(
		"OPTIMIZE=${CFLAGS}"
	)
	perl-module_src_compile
}
