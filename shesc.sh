#!/usr/bin/atf-sh

_do_shesc() {
  case "$*" in
  *\'*)
    ;;
  *)
    echo "'$*'"
    return
    ;;
  esac

  local in="$*" ; shift
  local ln=${#in}
  local oo="" q=""
  local i=0; while [ $i -lt $ln ]
  do
    local ch=${in:$i:1}
    case "$ch" in
    [a-zA-Z0-9.~_/+-])
      oo="$oo$ch"
      ;;
    \')
      q="'"
      oo="$oo'\\''"
      ;;
    *)
      q="'"
      oo="$oo$ch"
      ;;
    esac
    i=$(expr $i + 1)
  done
  echo "$q$oo$q"
}


shell_escape() { #$ Escape string for shell parsing
  #$ :usage: shell_escape [options] "string"
  [ $# -eq 0 ] && return 0 # Trivial case...
  local fq=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      #$ :param -q: Always include single quotes
      -q) fq=true ;;
      #$ :param --  End of options
      --) shift ; break ;;
      *) break ;;
    esac
    shift
  done
  #$ :param string : string to escape
  #$ :output: escaped string
  #$
  #$ shell_escape will examine the passed string in the
  #$ arguments and add any appropriate meta characters so that
  #$ it can be safely parsed by a UNIX shell.
  #$
  #$ It does so by enclosing the string with single quotes (if
  #$ it the string contains "unsafe" characters.).  If the string
  #$ only contains safe characters, nothing is actually done.
  if $fq ; then
    _do_shesc "$@"
    return $?
  fi
  if [ -z "$(echo "$*" | tr -d 'a-zA-Z0-9.~_/+-]')" ] ; then
    # All valid chars, nothing to be done...
    echo "$*"
    return 0
  fi
  _do_shesc "$@"
  return $?
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

  (
    set -euf -o pipefail
    _do_shesc one
    shell_escape two
    echo ''
  ) || atf_fail "Failed compiled"

}

xt_basic() {
  : =descr basic test
  [ x"$(xtf shell_escape one)" = x"one" ] || atf_fail "Fail#1"
  [ x"$(xtf shell_escape one two )" = x"'one two'" ] || atf_fail "Fail#2"
  [ x"$(xtf shell_escape -- abc )" = x"abc" ]  || atf_fail "Fail#3"
  [ x"$(xtf shell_escape -q one )" = x"'one'" ] || atf_fail "Fail#4"
}



xatf_init
