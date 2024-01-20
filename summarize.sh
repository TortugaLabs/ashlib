#!/usr/bin/atf-sh

summarize() { #$ show command progress without spamming the screen
  #$ :usage: cmd | summarize [done-msg]
  #$ :param [dome-msg]: message to show when command compeltes.  Defaults to "Done"
  #$ :input: output of a command
  #$ :output: the read input, but summarized as a single line.
  #$
  #$ This is to show progress of commands that will show too much
  #$ information.
  #$
  #$ The idea is that you feed the output of a command to summarize.
  #$ summarize will show the output on a single line.
  set +x
  while read -r L
  do
    printf '\r'
    local w=$(tput cols 2>/dev/null)
    if [ -n "$w" ] && [ $(expr length "$L") -gt $w ] ; then
      L=${L:0:$w}
    fi
    echo -n "$L"
    printf '\033[K'
  done
  [ $# -eq 0 ] && set - "Done"
  printf '\r'"$*"'\033[K\r\n'
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

  ( xtf summarize < /dev/null ) || atf_fail "Failed compilation"
}

xt_run() {
  [ $(seq 1 100 | xtf summarize | wc -l) -eq 1 ] || atf_fail "Failed to summarize"
}

xatf_init
