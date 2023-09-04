#!/usr/bin/atf-sh


trap __exit_handler EXIT
__exit_cmd=":"

__exit_handler() {
  eval "$__exit_cmd"
}

on_exit() { #$ register a command to be called on exit
  #$ :usage: on_exit exit_command
  #$ :param exit_command: command to execute on exit.
  #$
  #$ Adds a shell command to be executed on exit.
  #$
  #$ Instead of hooking `trap` _cmd_ `exit`, **on_exit** is cumulative,
  #$ so multiple calls to **on_exit** will not replace the exit handler
  #$ but add to it.
  #$
  #$ Only single commands are supported.  For more complex **on_exit**
  #$ sequences, declare a function and call that instead.
  __exit_cmd="$__exit_cmd ; $*"
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

  ( xtf on_exit : ) || atf_fail "Failed compilation"
}


xatf_init
