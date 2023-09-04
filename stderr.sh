#!/usr/bin/atf-sh

stderr() { #$ write to stderr
  #$ :usage: stderr message
  #$ Like the echo command but outputs to stdout instead ofstderr.
  #$
  #$ This could be done by echo and I/O redirection, but this is just
  #$ syntatically more pleasent.
  echo "$@" 1>&2
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh


xt_check() {
  : =descr "check"

  (xtf stderr) || atf_fail "compile check"
  [ -n "$(xtf stderr output 3>&1 1>&2 2>&3 3>&-) " ] || atf_fail "no-stderr"
  [ -z "$(xtf stderr stdout 2>/dev/null)" ]  || atf_fail "stdout found"
}

xatf_init
