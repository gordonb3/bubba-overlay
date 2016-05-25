# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
#
# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Add openjdk-bin (Debian build icedtea-bin for armel) as possible JDK provider
#
# $Id$

EAPI="6"

DESCRIPTION="Virtual for Java Development Kit (JDK)"
SLOT="1.8"
KEYWORDS="~arm"

RDEPEND="|| (
		dev-java/icedtea-bin:8
		dev-java/icedtea:8
		dev-java/oracle-jdk-bin:1.8
               	dev-java/openjdk-bin:8
	)"
