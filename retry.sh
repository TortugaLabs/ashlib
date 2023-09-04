#!/usr/bin/atf-sh

retry() { #$ retry a command until it succeeds
  local v=true count=60 delay=1
  #$ :usage: retry [options] cmd
  #$ :param --verbose: show '.' to indicate attempts
  #$ :param -0no-verbose: Do not show output
  #$ :param --count=number: number of retry attempts
  #$ :param --delay=seconds: wait this many seconds between attempts
  #$ :param cmd : command (or function) to execute
  while [ $# -gt 0 ]
  do
    case "$1" in
      --verbose|-v) v=true ;;
      --no-verbose|-q) v=false ;;
      --count=*) count=${1#--count=} ;;
      --delay=*) delay=${1#--delay=} ;;
      --) shift ; break ;;
      *) break ;;
    esac
    shift
  done
  #$ :outputs: if verbose, show progress.
  #$ :returns: true on success, false on failure
  #$
  #$ retry will attempt the given command until it succeeds up to
  #$ a maximum count attempts.  To avoid overloading the systems,
  #$ it will dealy attempts by the given delay (or 1 seconds if no
  #$ delay was specified.
  #$
  #$ If verbose is specified, it will show '.' per attempt.  And show
  #$ either "[TIMED-OUT]" or "[OK]" when completion on stderr.
  #$
  #$ Note that if the command being executed generates output it will
  #$ be displayed.
  while ! "$@"
  do
    $v && echo -n '.' 1>&2
    count=$(expr $count - 1)
    if [ $count -lt 1 ] ; then
      $v && echo ' [TIMED-OUT]' 1>&2
      return 1 # Failed
    fi
    sleep $delay
  done
  $v && echo ' [OK]' 1>&2
  return 0
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

  ( xtf retry true ) || atf_fail "Failed compilation"
}

xt_runs() {
  : =descr "Run compbinations"

  (
    start=$(date +%s)
    retry --count=3 --delay=1 false
    end=$(date +%s)
    [ $(expr $end - $start) -lt 2 ] && exit 1
    :
  ) || atf_fail "FAIL false-test"
  (
    start=$(date +%s)
    retry --count=3 --delay=1 true
    end=$(date +%s)
    [ $(expr $end - $start) -gt 1 ] && exit 1
    :
  ) || atf_fail "FAIL true-test"

  [ -n "$(retry --verbose --count=2 --delay=1 false 2>&1)" ] || atf_fail "FAIL#verbose"
  [ -z "$(retry --no-verbose --count=2 --delay=1 false 2>&1)" ] || atf_fail "FAIL#non-verbose"
}

xatf_init
