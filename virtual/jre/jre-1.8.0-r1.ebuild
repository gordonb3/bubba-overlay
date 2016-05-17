# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
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
