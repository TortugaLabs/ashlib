#!/usr/bin/atf-sh

cfv() { #$ Define a configurable variable
  #$ :usage: cfv VARIABLE default
  #$ :param VARIABLE: variable to check/init
  #$ :param default: default value if VARIABLE is not defined
  #$
  #$ Configurable variables
  #$
  #$ Define variables only if not specified.  It is used to
  #$ configure things via environment variables and provide
  #$ suitable defaults if there is none.
  #$
  #$ The way it works is to simply call the command like this:
  #$
  #$ ```bash
  #$ VARIABLE=value command args
  #$ ```
  #$
  #$ Then in the script, you woudld do:
  #$
  #$ ```bash
  #$ cfv VARIABLE default
  #$ ```
  eval local n=\${$1:-}
  if [ -n "$n" ] ; then
    export $1
    return
  fi
  eval export ${1}='"$2"'
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

  ( xtf cfv VAR value ) || atf_fail "Compile"
  [ x"$( VAR=100 xtf cfv VAR 0 ; echo $VAR)" = x"100" ] || atf_fail "FAIL#1"
  [ x"$( xtf cfv VAR 0 ; echo $VAR)" = x"0" ] || atf_fail "FAIL#2"

}

xatf_init
