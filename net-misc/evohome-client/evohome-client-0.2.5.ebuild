# Copyright 2015-2016 gordonb3 <gordon@bosvangennip.nl>
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="5"
PYTHON_COMPAT=( python{2_6,2_7,3_3,3_4} pypy2_0 )

inherit eutils python-r1 distutils-r1


SRC_URI="https://github.com/watchforstock/evohome-client/archive/${PV}.zip -> ${PN}-${PV}.zip"
RESTRICT="mirror"
DESCRIPTION="Python client to access the Evohome web service"
HOMEPAGE="http://domoticz.com/"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~arm ~ppc"
IUSE=""


RDEPEND="
	dev-python/python-dateutil
	dev-python/simplejson
	dev-python/requests
"

DEPEND="${RDEPEND}
	dev-python/pip
	dev-python/setuptools
"

