#!/usr/bin/atf-sh

fixlnk() { #$ Function to update symlinks
  #$ :usage: fixlnk [-D] target lnk
  local mkdir=false force=false
  #$ :param -D: if specified, link directory is created.
  #$ :param -f: if a file or directory of the sane name exists, it will be deleted.
  #$ :param target: where the link should be pointing to
  #$ :param lnk: where the link is to be created
  while [ $# -gt 0 ]
  do
    case "$1" in
    -D) mkdir=true ;;
    -f) force=true ;;
    *) break
    esac
    shift
  done
  #$ Will make sure that the given symlink exists and points to the
  #$ right location.
  #$
  #$ Note that this will first check if the symlink needs to be corrected.
  #$ Otherwise no action is taken.
  #$ :returns: true if file was changed, false if no change was performed
  if [ $# -ne 2 ] ; then
    echo "Usage: fixlnk {target} {lnk}" 1>&2
    return 10
  fi

  local lnkdat="$1"
  local lnkloc="$2"

  if [ -L "$lnkloc" ] ; then
    clnkdat=$(readlink "$lnkloc")
    [ x"$clnkdat" = x"$lnkdat" ] && return 0
    echo "Updating $lnkloc" 1>&2
    rm -f "$lnkloc"
  elif [ -e "$lnkloc" ] ; then
    if $forced ; then
      echo "Fixing $lnkloc" 1>&2
      rm -rf "$lnkloc"
    else
      return 1
    fi
  else
    echo "Creating $lnkloc" 1>&2
  fi
  $mkdir && [ ! -d "$(dirname "$lnkloc")" ] && mkdir -p "$(dirname "$lnkloc")"
  ln -s "$lnkdat" "$lnkloc"
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

  ( xtf fixlnk x y ) || atf_fail "Failed compilation"
}

xt_run() {
  : =descr "Run test"
  # -D
  # -f
  # defaults
  # new, modify, no-modify
}

xatf_init
