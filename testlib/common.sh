#!/bin/sh
[ -n "${IN_COMMON:-}" ] && return
IN_COMMON=true

. $(atf_get_srcdir)/testlib/xatf.sh

