


As of 25-06-2015 (EU date format) I've added a bubba metapackage that will provide you with core packages for your Excito B3, including the Bubba web frontend since 23-07-2015.

#### Prerequisits for running the Bubba web admin
The web admin interface requires a web server to operate. Supported web servers are apache2 and nginx, but it must be noted that if you want to use file uploads (currently not yet implemented in this overlay) you should choose apache or find the maximum file size to be very restricted (with apache it will be essentially unlimited). The packages default to using apache2 and if you're okay with that there's no need for changing anything. If however you like to use nginx you must at the same time disable apache2 USE flag on the bubba packages. This may seem like a lot of fuzz, but it prevents building (and needing to maintain) a lot of packages you don't actually need.


<p><br>Current optional packages are:</p>

#### Singapore 0.10.1
This is a web image gallery I'm offering as a replacement for bubba album. Quite fond of this app myself and a pre is that it does not require bulky, memory consuming, MySQL to run.
(Apache configured systems only - should work with nginx configured systems as well but will require manual configuration of the web server)


### 'Bubba-ized' Roundcube 1.0.6
The original portage ebuild for this app uses an install scheme that appears to be intended for much larger schemes than we're going for with this personel device. We also like to obfuscate web content that should be readily available (i.e. can not be deleted through the samba share) and this install matches the vhost definition we created for the bubba web admin interface.
(Apache configured systems only - should work with nginx configured systems as well but will require manual configuration of the web server)

#### File Transfer Daemon 0.55
This package adds download and upload capabilities to the bubba web admin. Uploading files requires the use of apache web server running the web admin. Downloading of torrents has been made an optional component (but is currently enabled by default) in this Excito original code that was written against rb_libtorrent &lt; 0.16. The torrent module has no magnet support and rb_libtorrent functions that currently only generate warnings about being deprecated may fail in the future. Torrent support may at some time default to not being enabled and eventually be removed all together.

#### Gentoo sources
Currently contains kernel versions 4.0.1 and 4.1.6, matching the kernels from sakaki's <a href="https://github.com/sakaki-/gentoo-on-b3">gentoo-on-b3</a> releases. These are copies of retired original gentoo releases, kept here for your convenience whenever you need need to build additional (3th party) modules.

#### Sysvinit-2.88-r100 (masked)
The high revision number is to keep out of the way of the main gentoo development and to keep this version on top as long as version 2.88 stays in use. The package contains a patched shutdown command that handles the hardware specific routine required for the Excito B3, meaning you can simply type 'halt' while in console, rather than running the prescribed flash writing tool 'write-magic' and then reboot as done by the Bubba web frontend. Also eliminates the regular TTY terminals which are useless on the B3 and sets the correct speed for the serial console. A sanity check is included by verifying that the system runs on a Kirkwood Feroceon SoC.

#### Bubba Easyfind 2.6
Originally this is part of the bubba-backend package, but I've decided to make this a separate package. Contains the various methods that allow you to use the myownb3.com dynamic DNS service. Only works with registered Excito brand B3's. By default all methods are installed, but you may control this by disabling the USE flags for non required methods (dhcp hook script | service to verify public address if behind a remote router).

Update: as of 27-07-2015 Rodeus, who now owns Excito, has taken control over the old Excito infrastructure that was temporarily and very gracefully hosted on the mybubba.org domain. New B3's should now also be able to use this service.


#### Logitech Media Server 7.8.0
Although being meant a binary distribution, they stopped shipping the platform dependant libraries for ARMv5 a long time ago. This is therefore a source build and it's perl dependencies may pull in up to ~100 additional packages.

#### Domoticz-9999
This is a home automation system build largely around the rfxtrx433 RF transceiver @433MHz. Information about the project can be found here: http://www.domoticz.com/ This is a rolling release using a subversion source.

#### Cryptodev paired with openssl (masked)
This serves no actual use but is merely a play thing. The B3 CPU contains a hardware encryption module that theoretically could speed up certain processes. Not so much because the hardware crypto engine is a lot quicker, but because it runs in parallel with your other processes. The trouble is that the supported encryption has fallen out of grace and is in fact no longer enabled by default in openssl. Try if you like, but don't expect any miracles.
