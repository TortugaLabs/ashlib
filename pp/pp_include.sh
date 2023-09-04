#!/usr/bin/atf-sh

###$_requires: find_in_path.sh

pp_include() { #$ file inclusion
  #$ :usage: pp_include file [file ...]
  #$ :usage: include() { pp_include "$@"; }
  #$ :param file: files to include
  #$
  #$ Used to implement file inclusion in pp.sh
  local oPATH="$PATH" f inc

  for inc in "$@"
  do
    f="$(find_in_path "$inc")"
    if [ -z "$f" ] ; then
      echo "$inc: not included" 1>&2
      continue
    fi
    local __FILE__="$f" __DIR__="$(dirname "$f")"
    export PATH="$oPATH:.:$(dirname "$f")"
    . "$f"
  done
  export PATH="$oPATH"
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

  . $(atf_get_srcdir)/../find_in_path.sh


  ( xtf pp_include ) || atf_fail "FAIL1"
  include() { pp_include "$@"; }
  ( xtf include ) || atf_fail "FAIL1"

  (
    set -euf -o pipefail
    export PATH=$(atf_get_srcdir)/testlib/pp_inc:$PATH
    pp_include test1.sh
    [ -z "${in_test1:-}" ] && exit 1
    [ -z "${in_test2:-}" ] && exit 1
    [ -z "${in_test3:-}" ] && exit 1
    exit 0
  ) || atf_fail "FAIL2"
}

xatf_init
