# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="Virtual for JDK"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="1.5"
KEYWORDS="~arm ~ppc"
IUSE=""

RDEPEND="|| (
		>=dev-java/gcj-jdk-4.3
		>=dev-java/cacao-0.99.2
		>=dev-java/jamvm-2.0.0
		=dev-java/sun-jdk-1.5.0*
	)"

