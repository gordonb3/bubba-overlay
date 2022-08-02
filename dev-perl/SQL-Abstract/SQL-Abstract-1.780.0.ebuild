# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7

DIST_AUTHOR=RIBASUSHI
DIST_VERSION=1.78
inherit perl-module

DESCRIPTION="Generate SQL from Perl data structures"

SLOT="0"
KEYWORDS="amd64 ~ppc x86 ~ppc-aix ~ppc-macos ~x86-solaris ~arm"
IUSE="test"

RDEPEND="
	>=dev-perl/Class-Accessor-Grouped-0.100.50
	>=dev-perl/Getopt-Long-Descriptive-0.91.0
	dev-perl/Hash-Merge
	dev-perl/Moo
"
DEPEND="${RDEPEND}
	dev-perl/Module-Install
	test? (
		>=dev-perl/Test-Deep-0.106
		dev-perl/Test-Exception
		dev-perl/Test-Pod
		>=virtual/perl-Test-Simple-0.92
		dev-perl/Test-Warn
		>=dev-perl/Clone-0.31
	)
"
