#!/usr/bin/atf-sh

check_opt() { #$ check options
  #$ :usage: check_opt [-q] variable [opt list]
  #$ :param -q: check if exists or not (true if exists, false if not)
  #$ :param --default=xxx: default value
  #$ :param variable: value to look-up
  #$ :param opt list: Usually `"$@"` if not specified uses `/proc/cmdline`
  local out=echo default=
  while [ $# -gt 0 ]
  do
    case "$1" in
    -q) out=: ;;
    --default=*) default=${1#--default=} ;;
    *) break ;;
    esac
    shift
  done
  local flag="$1" ; shift
  [ $# -eq 0 ] && set - $(cat /proc/cmdline)
  #$
  #$ Check option lines
  #$
  #$ :output: Will output the value assigned to `variable` unless `-q` is specified.
  #$ :returns: 0 if exists, 1 if it doesn't.

  for j in "$@"
  do
    if [ x"${j%=*}" = x"$flag" ] ; then
      $out "${j#*=}"
      return 0
    fi
  done
  [ -n "$default" ] && $out "$default"
  return 1
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_check() {
  : =descr "verify syntax..."

  ( xtf check_opt -q one one ) || atf_fail "Failed compilation"
  [ x"$( xtf check_opt one abc=one cbd=two one=one )" = x"one" ] || atf_fail "ERR#1"
  [ x"$( xtf check_opt joe abc=one cbd=two one=one )" = x"" ] || atf_fail "ERR#1"

}


xatf_init
