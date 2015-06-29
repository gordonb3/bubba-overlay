# Bubba overlay for Gentoo
This is work in progress, adding functions to the Excito B3 that are not in the regular portage tree or require additional patches

As of 25-06-2015 (EU date format) I've added a bubba metapackage that will provide you with vital packages for your Excito B3. This package is required if you want to install the platform specific version of sysvinit that will give your system working 'shutdown' and 'halt' commands.


Current optional packages are:

#### Logitech Media Server
Although being meant a binary distribution, they stopped shipping the platform dependant libraries for ARMv5 a long time ago. This is therefore a source build and it's perl dependencies may pull in up to ~100 additional packages.

#### Domoticz
This is a home automation system build largely around the rfxtrx433 RF transceiver @433MHz. Information about the project can be found here: http://www.domoticz.com/ This is a rolling release using a subversion source.

#### Cryptodev paired with openssl (masked)
This serves no actual use but is merely a play thing. The B3 CPU contains a hardware encryption module that theoretically could speed up certain processes. Not so much because the hardware crypto engine is a lot quicker, but because it runs in parallel with your other processes. The trouble is that the supported encryption has fallen out of grace and is in fact no longer enabled by default in openssl. Try if you like, but don't expect any miracles.
