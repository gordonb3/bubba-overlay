# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR=AGRUNDMA
# Note: 1.02 was never officially marked `release`, so we are grabbing 1.01 and patch it to reach 1.02
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

PATCHES=( "${FILESDIR}/fix_Opus_duration_bug.patch" )


src_compile() {
	mymake=(
		"OPTIMIZE=${CFLAGS}"
	)
	perl-module_src_compile
}
