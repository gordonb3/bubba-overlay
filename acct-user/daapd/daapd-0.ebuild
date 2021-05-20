# Copyright 2021 Gordon Bos
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for iTunes Digital Audio Access Protocol server"
ACCT_USER_ID=112
ACCT_USER_GROUPS=( daapd )

acct-user_add_deps
