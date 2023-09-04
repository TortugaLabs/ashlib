#!/usr/bin/atf-sh

is_mounted() ( #$ check if directory is a mounted mount point
  #$ :usage:
  #$ :param directory: directory moint point
  #$ :returns: true if mounted, false if not
  #$
  #$ Determine if the given directory is a mount point
  [ "$1" = none ] && return 1
  [ -d "$1" ] || return 1
  [  $(awk '$2 == "'"$1"'" { print }' /proc/mounts | wc -l) -eq 1 ] && return 0
  return 1
)


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_check() {
  : =descr "check"

  ( xtf is_mounted / ) || atf_fail "FAIL#1"
  t=$(mktemp -d)
  ( is_mounted  "$t") && atf_fail "FAIL#2" || :
  rmdir "$t"
  ( is_mounted none ) && atf_fail "FAIL#3" || :
  ( is_mounted /bad/dir ) && atf_fail "FAIL#4" || :
}

xatf_init
