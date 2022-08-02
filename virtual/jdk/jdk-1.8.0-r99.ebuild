# Copyright 2015-2022 gordonb3 <gordon@bosvangennip.nl>
# Add openjdk-bin (Debian build icedtea-bin for armel) as possible JDK provider
#
# $Id$

EAPI="7"

DESCRIPTION="Virtual for Java Development Kit (JDK)"
SLOT="1.8"
KEYWORDS="~arm"

RDEPEND="|| (
		dev-java/icedtea-bin:8
		dev-java/icedtea:8
		dev-java/oracle-jdk-bin:1.8
               	dev-java/openjdk-bin:8
	)"
