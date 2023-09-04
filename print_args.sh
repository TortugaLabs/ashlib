#!/usr/bin/atf-sh

print_args() { #$ print arguments
  #$ :usage: print_args --sep=xyz [arguments]
  #$
  #$ Print command line arguments to stdout
  #$
  #$ Optionally use a separator instead of new line.
  #|****
  [ "$#" -eq 0 ] && return 0
  case "$1" in
  --sep=*|-1)
    if [ x"$1" = x"-1" ] ; then
      local sep='\x1'
    else
      local sep="${1#--sep=}"
    fi
    shift
    local i notfirst=false
    for i in "$@"
    do
      $notfirst && echo -n -e "$sep" ; notfirst=true
      echo -n "$i"
    done
    return
    ;;
  esac
  local i
  for i in "$@"
  do
    echo "$i"
  done
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

  local x='1
2
3'

  (xtf print_args 1 2) || atf_fail "compile check"
  [ x"$(xtf print_args 1 2 3)" = x"$x" ] || atf_fail "ERR#1"
  [ x"$(xtf print_args -1 1 2 3 | cat -v)" = x"1^A2^A3" ] ||  atf_fail "ERR#2"
  [ x"$(xtf print_args --sep="\x02" 1 2 3 | cat -v)" = x"1^B2^B3" ] ||  atf_fail "ERR#2"
}

xatf_init
