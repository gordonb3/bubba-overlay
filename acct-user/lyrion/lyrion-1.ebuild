# Copyright 2024 Gordon Bos
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for Lyrion Music Server"
ACCT_USER_ID=641
ACCT_USER_GROUPS=( lyrion )

acct-user_add_deps
