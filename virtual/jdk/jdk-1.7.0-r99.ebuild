# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

DESCRIPTION="Virtual for Java Development Kit (JDK)"
SLOT="1.7"
KEYWORDS="~arm"

RDEPEND="|| (
		dev-java/icedtea-bin:7
		dev-java/icedtea:7
		dev-java/oracle-jdk-bin:1.7
		dev-java/openjdk-bin:7
	)"
