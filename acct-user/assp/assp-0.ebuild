# Copyright 2022 Gordon Bos
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for Anti Spam SMTP Proxy server"
ACCT_USER_ID=116
ACCT_USER_GROUPS=( assp )

acct-user_add_deps
