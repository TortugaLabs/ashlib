#!/usr/bin/atf-sh

find_in_path() { #$ Find a file in a path
  #$ :usage: find_in_path [--path=PATH] file
  #$ :param --path=PATH: don't use $PATH but the provided PATH
  #$ :param file: file to find
  #$ :returns: 0 if found, 1 if not found
  #$ :output: full path of found file
  #$
  #$ Find a file in the provided path or PATH environment
  #$ variable.
  local spath="$PATH"
  while [ $# -gt 0 ]
  do
    case "$1" in
    --path=*)
      spath="${1#--path=}"
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  if [ x"${1:0:1}" = x"/" ] ; then
    [ -f "$1" ] && echo "$1" && return 0
    return 1
  fi
  local d oIFS="$IFS" ; IFS=":"
  for d in $spath
  do
    if [ -f "$d/$1" ] ; then
      echo "$d/$1"
      IFS="$oIFS"
      return 0
    fi
  done
  IFS="$oIFS"
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
  : =descr "check"

  ( xtf find_in_path "atf-sh" ) || atf_fail "FAIL1"
  [ -n "$(xtf find_in_path "atf-sh")" ] || atf_fail "FAIL2"
  ( xtf find_in_path "missing$$" ) && atf_fail "FAIL3" || :
  [ -z "$(xtf find_in_path "missing$$")" ] || atf_fail "FAIL4" || :
}

xatf_init
