#!/usr/bin/atf-sh
#$ Setup python environments

pysetup() { #$ setup a python virtual environment
  #$ :usage: pysetup venvdir ospkgs pip_pkgs ... cmd_line_args ...
  #$ :param venvdir: Path to python virtual environment
  #$ :param ospkgs: OS packages that need to be pre-installed
  #$ :param pip_pkgs: PIP pkgs to install in virtual environment
  #$ :param cmd_line_args: pass "$@"
  #$
  #$ Check if a virtual environment exists or needs to be re-installed
  #$ and sets it up if necessary.
  #$
  local pydir="$1" ; shift
  local ospkgs="$1" ; shift
  local pypkgs="$1" ; shift

  local quit=false r missing

  if [ $# -gt 0 ] && [ x"$1" = x"--reinstall" ] ; then
    rm -rf "$pydir"
    local quit=true
  fi

  dsc=$(readlink -f "$pydir" ; echo "$ospkgs" ; echo "$pypkgs" ; declare -f pysetup)
  if [ -d "$pydir" ] ; then
    cur=$(cat "$pydir/state.txt" || :)
    if [ x"$cur" = x"$dsc" ] ; then
      . "$pydir"/bin/activate
      return
    fi
    rm -rf "$pydir"
  fi

  # Check for pre-requisites
  missing=""
  for r in $ospkgs
  do
    xbps-query "$r" || missing="$missing $r"
  done
  if [ -n "$missing" ] ; then
    echo "Missing packages:$missing" 1>&2
    exit 34
  fi

  python3 -m venv --system-site-packages "$pydir"
  (
    . "$pydir"/bin/activate
    if [ -n "$pypkgs" ] ; then
      pip install $pypkgs
    fi
  ) || exit 1
  echo "$dsc" > "$pydir/state.txt"
  $quit && exit 0
  . "$pydir"/bin/activate
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
  t=$(mktemp -d)
  rc=0
  ( set -euf -o pipefail ; pysetup "$t" "" "" ) || rc=$?
  rm -rf "$t"
  [ $rc -ne 0 ] && atf_fail "ERROR#$rc"
  :
}


xatf_init
