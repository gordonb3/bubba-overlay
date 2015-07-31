# Bubba overlay for Gentoo
This is work in progress, adding functions to the Excito B3 that are not in the regular portage tree or require additional patches

As of 25-06-2015 (EU date format) I've added a bubba metapackage that will provide you with core packages for your Excito B3, including the Bubba web frontend since 23-07-2015.


Current optional packages are:

#### Gentoo sources 4.0.1
This is a copy of the retired original gentoo release. If you're running Sakaki's kernel and need to build additional (3th party) modules, you'll need this source.

#### Sysvinit-9999
Although not a rolling release, this was given version number 9999 to stay on top indefinitely. It contains a patched shutdown command that handles the hardware specific routine required for the Excito B3, meaning you can simply type 'halt' while in console, rather than running the prescribed write-magic and reboot as done by the Bubba web frontend. Also eliminates the regular TTY terminals which are useless on the B3 and sets the correct speed for the serial console. A sanity check is included by verifying that the system runs on a Kirkwood Feroceon SoC.

#### Bubba Easyfind 2.6
Originally this is part of the bubba-backend package, but I've decided to make this a separate package. Contains the various methods that allow you to use the myownb3.com dynamic DNS service. Only works with registered Excito brand B3's. By default all methods are installed, but you may control this by disabling the USE flags for non required methods (dhcp hook script | service to verify public address if behind a remote router).

Update: as of 27-07-2015 Rodeus, who now owns Excito, has taken control over the old Excito infrastructure that was temporarily and very gracefully hosted on the mybubba.org domain. New B3's should now also be able to use this service.


#### Logitech Media Server 7.8.0
Although being meant a binary distribution, they stopped shipping the platform dependant libraries for ARMv5 a long time ago. This is therefore a source build and it's perl dependencies may pull in up to ~100 additional packages.

#### Domoticz-9999
This is a home automation system build largely around the rfxtrx433 RF transceiver @433MHz. Information about the project can be found here: http://www.domoticz.com/ This is a rolling release using a subversion source.

#### Cryptodev paired with openssl (masked)
This serves no actual use but is merely a play thing. The B3 CPU contains a hardware encryption module that theoretically could speed up certain processes. Not so much because the hardware crypto engine is a lot quicker, but because it runs in parallel with your other processes. The trouble is that the supported encryption has fallen out of grace and is in fact no longer enabled by default in openssl. Try if you like, but don't expect any miracles.
