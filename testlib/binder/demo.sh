#!/bin/sh
#
# Binder test
#
###$_begin-include: die.sh

die() {
  local rc=1
  [ $# -eq 0 ] && set - -1 EXIT
  case "$1" in
    -[0-9]*) rc=${1#-}; shift ;;
  esac
  echo "$@" 1>&2
  exit $rc
}

###$_end-include: die.sh
###$_include: die.sh
###$_begin-include: retry.sh
retry() {
  local v=true count=60 delay=1
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

###$_end-include: retry.sh
###$_begin-include: two.sh
#
# Demo
#
###$_requires-satisfied: die.sh as /home/alex/ww/ashlib-bounded/die.sh

_do_shesc() {
  case "$*" in
  *\'*)
    ;;
  *)
    echo "'$*'"
    return
    ;;
  esac

  local in="$*" ; shift
  local ln=${#in}
  local oo="" q=""
  local i=0; while [ $i -lt $ln ]
  do
    local ch=${in:$i:1}
    case "$ch" in
    [a-zA-Z0-9.~_/+-])
      oo="$oo$ch"
      ;;
    \')
      q="'"
      oo="$oo'\\''"
      ;;
    *)
      q="'"
      oo="$oo$ch"
      ;;
    esac
    i=$(expr $i + 1)
  done
  echo "$q$oo$q"
}


shell_escape() {
  [ $# -eq 0 ] && return 0 # Trivial case...
  local fq=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      #   * -q : Always include single quotes
      -q) fq=true ;;
      #   * -- : End of options
      --) shift ; break ;;
      *) break ;;
    esac
    shift
  done
  if $fq ; then
    _do_shesc "$@"
    return $?
  fi
  if [ -z "$(echo "$*" | tr -d 'a-zA-Z0-9.~_/+-]')" ] ; then
    # All valid chars, nothing to be done...
    echo "$*"
    return 0
  fi
  _do_shesc "$@"
  return $?
}


two() {
  echo two
}
###$_end-include: two.sh

[ $# -eq 0 ] && die "Usage: $0 yeah yeah"

