# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

# This file contains a custom OS package to provide information on the
# installation structure on Gentoo.

package Slim::Utils::OS::Custom;

use strict;

use base qw(Slim::Utils::OS::Linux);

sub initDetails {
	my $class = shift;

	$class->{osDetails} = $class->SUPER::initDetails();

	$class->{osDetails}->{isGentoo} = 1 ;
	$class->{osDetails}->{osName} = 'Gentoo Linux';

	# Ensure we find manually installed plugin files.
	push @INC, '/var/lib/lyrionmusicserver';
	push @INC, '/var/lib/lyrionmusicserver/Plugins';

	return $class->{osDetails};
}

=head2 dirsFor( $dir )

Return OS Specific directories.

Argument $dir is a string to indicate which of the Lyrion Music Server
directories we need information for.

=cut

sub dirsFor {
	my ($class, $dir) = @_;

	my @dirs = ();

	# Overrides for specific directories.
	if ($dir eq 'Plugins') {

		# Look in the normal places.
		push @dirs, $class->SUPER::dirsFor($dir);

		# User-installed plugins are in a different place, so add it.
		push @dirs, '/var/lib/lyrionmusicserver/Plugins';

	} elsif ($dir eq 'ClientPlaylists') {

		# LMS would normally try to put client playlists in the prefs
		# directory, but they aren't really prefs since they're dynamic
		# state of the clients. Effectively, they're the same as the
		# database cache, so we move these under /var/lib.
		push @dirs, '/var/lib/lyrionmusicserver/ClientPlaylists';

	} elsif ($dir =~ /^(?:prefs)$/) {

		# Server and plugin preferences are in a different place.
		push @dirs, $::prefsdir || '/var/lib/lyrionmusicserver/preferences';

	} elsif ($dir eq 'log') {

		push @dirs, $::logdir || "/var/log/lyrionmusicserver";

	} elsif ($dir eq 'cache') {

		push @dirs, $::cachedir || "/var/lib/lyrionmusicserver/cache";

	} else {

		# Use the default behaviour to locate the directory.
		push @dirs, $class->SUPER::dirsFor($dir);

	}

	return wantarray() ? @dirs : $dirs[0];
}

1;

__END__
