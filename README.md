
# Bubba overlay for [gentoo-on-b3](https://github.com/sakaki-/gentoo-on-b3/)

#### Description

<img src="https://raw.githubusercontent.com/gordonb3/cache/master/Bubba/Excito-B3.jpg" alt="Excito B3" width="250px" align="right"/>
This project contains an overlay for Gentoo that will bring the original Excito web based User Interface back to the B3 miniserver. The port is however not an exact mirror of the original Bubba OS. The old Horde webmail app was replaced by Roundcube and I selected SQLite as the database backend, which saves a lot of memory on the box. For the same reason I did not add bubba-album to this overlay but I did put in a replacement that use csv files and may optionally also use SQLite: Singapore Gallery.

Unlike the original interface you may select what you want or don't want on the box. This speeds up updates because you don't need to build packages you don't use. Most of them at least. Some packages also contain USE flags that allow you even more control over what gets installed. If you want to have the full Bubba OS experience, simply run `emerge @bubba3`. For basic functionality run `emerge @bubba`

Note: on Bubba|2 you should run `emerge @bubba2`. This set excludes forked-daapd which appears to be impossible to build on ppc.

#### 


#### Prerequisits for running the Bubba web admin
An Excito B2 or B3 running Gentoo of course!

The web admin interface requires a web server to operate. Supported web servers are apache2 and nginx, but it must be noted that if you want to use file uploads you should choose apache or find the maximum file size to be very restricted (with apache it will be essentially unlimited). The packages default to using apache2 and if you're okay with that there's no need for changing anything. If however you like to use nginx you must at the same time disable apache2 USE flag on the bubba packages. This may seem like a lot of fuzz, but it prevents building (and needing to maintain) a lot of packages you don't actually need.

<p><br>Packages included in the @bubba2 and @bubba3 sets are:</p>

#### Singapore 0.10.1 (unmaintained)
This is a web image gallery I'm offering as a replacement for bubba album. Quite fond of this app myself and a pre is that it does not require bulky, memory consuming, MySQL to run.
(Apache configured systems only - should work with nginx configured systems as well but will require manual configuration of the web server)

#### 'Bubba-ized' Roundcube
The original portage ebuild for this app uses an install scheme that appears to be intended for much larger schemes than we're going for with this personal device. We also like to obfuscate web content that should be readily available (i.e. can not be deleted through the samba share) and this install matches the vhost definition we created for the bubba web admin interface.
(Apache configured systems only - should work with nginx configured systems as well but will require manual configuration of the web server)

#### File Transfer Daemon
This package adds download and upload capabilities to the bubba web admin. Uploading files requires the use of apache web server running the web admin. The original additional feature to download torrents was removed in March 2020 as conflicts with supporting libraries could no longer be resolved.

#### Lyrion Music Server
Formerly known as Logitech Media Server this used to be a binary distribution, however they stopped shipping the platform dependent libraries for ARMv5 and PowerPC a long time ago. This is a source build and it's perl dependencies may pull in up to ~100 additional packages and will take quite some time to complete.

<p><br>Optional packages included in the overlay are:</p>

#### Domoticz
This is a home automation system. Information about the project can be found here: http://www.domoticz.com/

#### Oikomaticz
My personal port of Domoticz featuring various code optimizations for embedded devices and some additional hardware support. This is a rolling release using a git source but I do create ebuilds for specific commits on a regular base.

#### Anti-Spam SMTP Proxy Server (ASSP)
An Anti-SPAM filter that sits between the internet and your SMTP receiving email server.

[![Buy me a beer!](https://raw.githubusercontent.com/gordonb3/cache/master/Algemeen/Buy%20me%20a%20beer!.png)](https://www.paypal.com/donate/?hosted_button_id=USJR8BWKEAEAL)

