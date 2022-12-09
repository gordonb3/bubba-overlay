# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="7"

DESCRIPTION="Anti-Spam SMTP Proxy written in Perl"
HOMEPAGE="http://assp.sourceforge.net/"
MY_PN=ASSP_${PV/.16/_16}_install
SRC_URI="https://iweb.dl.sourceforge.net/project/${PN}/ASSP%20Installation/ASSP%201.10.X/${MY_PN}.zip"
RESTRICT="mirror"
LICENSE="GPL-2"
SLOT="0"

KEYWORDS="~arm"

IUSE="ipv6 ldap sasl spf srs ssl syslog"

DEPEND="app-arch/unzip"

RDEPEND="
	acct-user/assp
	acct-group/assp
	dev-lang/perl
	dev-perl/Net-DNS
	dev-perl/File-ReadBackwards
	virtual/perl-IO-Compress
	dev-perl/Email-MIME
	dev-perl/Email-Send
	dev-perl/Email-Valid
	dev-perl/libwww-perl
	dev-perl/mime-construct
	dev-perl/Net-CIDR-Lite
	virtual/perl-Digest-MD5
	virtual/perl-Time-HiRes
	ipv6? ( dev-perl/IO-Socket-INET6 )
	sasl? ( dev-perl/Authen-SASL )
	spf? ( dev-perl/Mail-SPF )
	srs? ( dev-perl/Mail-SRS )
	ssl? ( dev-perl/IO-Socket-SSL )
	syslog? ( virtual/perl-Sys-Syslog )
	ldap? ( dev-perl/perl-ldap )"

S=${WORKDIR}/${MY_PN}/ASSP

src_prepare() {
	eapply_user

	# just being safe
	for file in $(ls -1 *.pl); do
		sed -i 's/\r$//' ${file}
	done

	# portable changes via sed vs patch
	sed -i -e 's|file:files/|file:/var/lib/assp/conf/|' \
		-e 's|$base/images|/opt/assp/images|' \
		-e 's|logs/maillog.txt|/var/log/assp/maillog.txt|' \
		-e 's|PID File'\'',40,textinput,'\''pid'\''|PID File'\'',40,textinput,'\''asspd.pid'\''|' \
		-e 's|Daemon\*\*'\'',0,checkbox,0|Daemon\*\*'\'',0,checkbox,1|' \
		-e 's|UID\*\*'\'',20,textinput,'\'''\''|UID\*\*'\'',20,textinput,'\''assp'\''|' \
		-e 's|GID\*\*'\'',20,textinput,'\'''\''|GID\*\*'\'',20,textinput,'\''assp'\''|' \
		-e 's|popFileEditor'\('\\'\''pb/pbdb\.\([^\.]*\)\.db\\'\'',|popFileEditor(\\'\''/var/lib/assp/pb/pbdb.\1.db\\'\'',|g' \
		-e 's|$base/assp.cfg|/var/lib/assp/conf/assp.cfg|g' \
		-e 's|$base/$pidfile|/run/assp/asspd.pid|' \
		-e 's|mkdir "$base/$logdir",0700 if $logdir;||' \
		-e 's|mkdir "$base/$logdir",0700;||' \
		-e 's|$base/$logfile|$logfile|' \
		-e 's|$base/$logdir|$logdir|' \
		-e 's|"maillog.log"|"/var/log/assp/maillog.log"|' \
		-e 's|-d "$base/logs" or mkdir "$base/logs",0700;||' \
		-e 's|-d "$base/notes" or mkdir "$base/notes",0700;||' \
		-e 's|-d "$base/docs" or mkdir "$base/docs",0777;||' \
		-e 's|$base/$archivelogfile|$archivelogfile|' \
		-e 's|"$base/$file",$sub,"$this|"/var/lib/assp/conf/$file",$sub,"$this|' \
		-e 's|"$base/$file",'\'''\'',"$this|"/var/lib/assp/conf/$file",'\'''\'',"$this|' \
		-e 's|my $fil=$1; $fil="$base/$fil" if $fil!~/^\\Q$base\\E/i;|my $fil=$1;|' \
		-e 's|$fil="$base/$fil" if $fil!~/^\\Q$base\\E/i;|$fil="/var/lib/assp/$fil" if $fil!~/^\\/var\\/lib\\/assp\\/conf\\/\|\\/var\\/lib\\/assp\\/\/i;|' \
		-e 's|$fil="$base/$fil" if $fil!~/^((\[a-z\]:)?\[\\/\\\\\]\|\\Q$base\\E)/;||' \
		-e 's|if ($fil !~ /^\\Q$base\\E/i) {|if ($fil !~ /^\\/opt\\/assp\\//i) {|' \
		-e 's|$fil = "$base/$fil";|$fil = "/opt/assp/$fil";|' \
		-e 's|Q$base\\E|Q\\/var\\/lib\\/assp\\/\\E|' \
		-e 's|$fil="$base/$fil"|$fil="/var/lib/assp/$fil"|' \
		-e 's|$base/$bf|/var/lib/assp/conf/$bf|g' \
		-e 's|rebuildrun.txt|/var/lib/assp/rebuildrun.txt|' \
		assp.pl || die

	# remove windows stuff
	rm "addservice.pl"
	rm -f "Win32-quickstart-guide.txt"
}

src_install() {
	# Configuration directory
	insinto /var/lib/assp/conf
	# Installs files that are used by assp for black/gray lists,
	# and domain country lookup. To be changed by admin as needed.
	doins files/*.txt

	fowners assp:assp /var/lib/assp/conf -R
	fperms 770 /var/lib/assp/conf

	# Setup directories for mail to be stored for filter
	keepdir /var/lib/assp/spam /var/lib/assp/notspam
	keepdir /var/lib/assp/errors/spam /var/lib/assp/errors/notspam

	# Logs directory
	keepdir /var/log/assp
	fowners assp:assp -R /var/log/assp
	fperms 770 /var/log/assp

	# Install the app
	exeinto /opt/assp
	doexe *.pl
	insinto /opt/assp
	doins -r images/

	# Lock down the files/data
	fowners assp:assp -R /opt/assp
	fperms 770 /opt/assp

	# Data storage
	fowners assp:assp -R /var/lib/assp
	fperms 770 /var/lib/assp

	# Install the init.d script to listen
	newinitd "${FILESDIR}/asspd.init" asspd

	local HTML_DOCS="docs/*.htm"
	einstalldocs
}

pkg_postinst() {
	elog
	elog "To configure ASSP, start /etc/init.d/asspd then point"
	elog "your browser to http://localhost:55555"
	elog "Username: admin  Password: nospam4me (CHANGE ASAP!)"
	elog
	elog "File permissions have been set to use assp:assp"
	elog "with mode 770 on directories.  When you configure"
	elog "ASSP, make sure and use the user assp."
	elog
	elog "Don't change any path related options."
	elog
	elog "See the on-line docs for a complete tutorial."
	elog "http://assp.sourceforge.net/docs.html"
	elog
	elog "If upgrading, please update your old config to set both"
	elog "redre.txt and nodelay.txt path of /var/lib/assp/conf.  There are"
	elog "also many new options that you should review."
	elog
}


