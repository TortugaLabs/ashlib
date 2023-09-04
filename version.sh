#!/usr/bin/atf-sh
ashlib_version=$(echo '
###$_requires: VERSION
' |grep -v '^$')

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_check() {
  : =descr "check"
  f=$(mktemp) ; rc=0
  (
    set -euf
    ( echo '###$_include: version.sh' ; echo 'echo "$ashlib_version"' ) > $f
    python3 binder.py $f
    input=$(sh "$f")
    output=$(cat VERSION)
    [ x"$input" = x"$output" ]
  ) || rc=$?
  rm -f $f
  [ $rc -eq 0 ] && return 0
  atf_fail 'fail'
}

xatf_init
