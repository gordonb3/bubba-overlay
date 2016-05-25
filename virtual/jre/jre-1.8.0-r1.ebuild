# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
#
# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Add oracle embedded JDK as possible JRE provider
#
# $Id$

EAPI="6"

DESCRIPTION="Virtual for Java Runtime Environment (JRE)"
SLOT="1.8"
KEYWORDS="~arm"

RDEPEND="|| (
		virtual/jdk:1.8
		dev-java/oracle-jre-bin:1.8
		dev-java/oracle-ejdk-bin:1.8
	)"
