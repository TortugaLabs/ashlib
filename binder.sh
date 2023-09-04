#!/usr/bin/atf-sh

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

binder=$(atf_get_srcdir)/binder.py

xt_syntax() {
  : =descr "verify syntax..."

  w=$(mktemp -d)
  rc=0
  (
    set -euf -o pipefail
    set -x
    cp -a "$binder" "$w/binder.py"
    cd $w
    python3 -m py_compile binder.py
  ) || rc=$?
  rm -rf "$w"
  [ $rc -eq 0 ] || atf_fail "Compile test"
}

# TODO:tests
# - -I
# - test include heristics
# - bind -> unbind
# - file changing
# - Meta
# - -f force
# - -d
# pipe-filter or file
# recursive
# pattern cfg
# pattern cli
# pattern cli file
# dry-run

xatf_init
