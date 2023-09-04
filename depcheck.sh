#!/usr/bin/atf-sh

depcheck() { #$ Check file dependancies
  #$ :usage: depcheck [options] <target> [depends]
  #$ :param --verbose: show dependancy failures
  #$ :param target: file that needs to be built
  #$ :param depends : file components used to build target
  #$ :returns: true if target needs to be re-build.  false if target is up-to-date.
  #$
  #$ Given a "target" will make sure that it is newer of all the
  #$ dependancies
  #$
  #$ depcheck would do a dependancy check (similar to what `make`
  #$ does).  It finds all the files in `depends` and make sure that
  #$ all files are older than the target.
  verbose=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      --verbose|-v) verbose=true ;;
      *) break ;;
    esac
    shift
  done
  local target="$1" ; shift
  [ ! -f "$target" ] && return 0
  local tdate=$(date -r "$target" '+%s')

  find "$@" -type f | (
    while read f
    do
      local ddate=$(date -r "$f" +'%s')
      if [ $tdate -lt $ddate ] ; then
	$verbose && echo $target $tdate:$ddate $f 1>&2
	exit 0
      fi
    done
    exit 1
  )
  return $?
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_depcheck() {
  : =descr "check"

  (xtf depcheck /dev/null ) || atf_fail "compile check"


  > d1 ; > d2 ; rm -f t1
  (xtf depcheck t1 d1 d2) || atf_fail "1.target should rebuild"

  >d1 ; > d2 ; > t1
  (xtf depcheck t1 d1 d2) && atf_fail "2.target does not rebuild" || :

  >t1 ; >d1 ; sleep 1 ; > d2
  (xtf depcheck t1 d1 d2) || atf_fail "3.target should rebuild"

  > d1 ; > d2 ; rm -f t1
  [ -z "$(xtf depcheck -v t1 d1 d2 2>&1)" ] || atf_fail "1a.target should rebuild"

  >d1 ; > d2 ; > t1
  [ -z "$(xtf depcheck -v t1 d1 d2 2>&1)" ] || atf_fail "2a.target does not rebuild"

  >t1 ; >d1 ; sleep 1 ; > d2
  [ -n "$(xtf depcheck -v t1 d1 d2 2>&1)" ]  || atf_fail "3a.target should rebuild"

  rm -f t1 d1 d2
}

xatf_init
