#!/usr/bin/atf-sh

###$_requires: find_in_path.sh

_include_once_file_list=""
include() { #$  include file from PATH
  #$ :usage: include [--once] module [other modules ...]
  #$ :param --once|-1: if specified, modules will not be included more than once
  #$ :param module: module to include
  #$ :returns: true on success, false on failure.  The return code number corresponds to the number of failed modules
  #$
  #$ **LIMITATIONS**: module names can not have white space
  local once=false

  while [ $# -gt 0 ]
  do
    case "$1" in
    --once|-1)
      once=true
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  local ext fn i c=0
  for i in "$@"
  do
    if $once ; then
      # Check if it has been included already
      for fn in $_include_once_file_list
      do
	# Yes, so skip it
	[ "$fn" = "$i" ] && continue 2
      done
    fi

    for ext in ".sh" ""
    do
      if fn=$(find_in_path $i$ext) ; then
	if [ -z "$_include_once_file_list" ] ; then
	  _include_once_file_list="$i"
	else
	  _include_once_file_list="$_include_once_file_list $i"
	fi
	. $fn
	break
      fi
    done
    if [ -z "$fn" ] ; then
      echo "$i: not found" 1>&2
      c=$(expr $c + 1)
    fi
  done
  return $c
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

  . $(atf_get_srcdir)/find_in_path.sh

  ( xtf include -1 ) || atf_fail "Compile"

  (
    set -euf -o pipefail
    export PATH=$PATH:$(atf_get_srcdir)/testlib/include
    include inc1
    [ -n "${count:-}" ] || exit 1
    [ $count -eq 1 ] || exit 2
    include inc1
    [ $count -eq 2 ] || exit 3
    include -1 inc1
    [ $count -eq 2 ] || exit 4
  ) || atf_fail "include:$?"

}

xatf_init
