#!/usr/bin/atf-sh

die() { #$  exit script with status
  #$ :usage: die [-rc] [msg]
  #$ :param -int: will exit with erro-code `int`
  #$ :param msg: message to display on stderr
  local rc=1
  [ $# -eq 0 ] && set - -1 EXIT
  case "$1" in
    -[0-9]*) rc=${1#-}; shift ;;
  esac
  #$
  #$ Exit script display error and with the given exit code
  #$
  #$ The default is to use exit code "1" and show "EXIT" on stderr.
  #$ :output:  Will show the given message on stderr.
  #$ :return: Will exit the given return code.
  echo "$@" 1>&2
  exit $rc
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_syntax() {
  : =descr "verify syntax..."

  ( xtf die -0 ) || atf_fail "Failed compilation"
}

xt_runs() {
  : =descr "Run compbinations"

  [ -z "$( xtf die -0)" ] || atf_fail "fail#1"
  [ -n "$( xtf die -0) msg" ] || atf_fail "fail#1"
  [ $(xtf_rc die -5 one) -eq 5 ] || atf_fail "fail#3"
}

xatf_init
