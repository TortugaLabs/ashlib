#!/bin/sh
#
#|****m* xatf/xatf
#| DESCRIPTION
#|   Functions to extend ATF
#|
#|   These functions are used for convenience to enhance
#|   https://github.com/jmmv/atf libraries to be used
#|   with https://github.com/jmmv/kyua/ testing engine.
#|
#|****
#
[ -z "${XTF_OUTPUT_TRACE:-}" ] && XTF_OUTPUT_TRACE=false

#|****f* xatf/xatf_auto_init_test_cases
#| NAME
#|   xatf_auto_init_test_cases -- Create `atf_init_test_cases`
xatf_auto_init_test_cases() {
  #| USAGE
  #|   N/A -- used by xatf_init
  #| DESCRIPTION
  #|   This function creates the `atf_init_test_cases` function
  #| that initializes test cases.  It does so by creating a list
  #| of functions and picking the ones that end with `_head`.
  #|****
  local i fn="atf_init_test_cases() {"
  for i in $(declare -F | awk '$1 == "declare" && $2 == "-f" && $3 ~ /_head$/ && $3 !~ /^_atf_/ { print $3 }' | sed -e 's/_head$//')
  do
    fn="$fn
	atf_add_test_case $i"
  done
  fn="$fn
      }"
  eval "$fn"
}

: ${_XATF_INITED:=false}
#|****f* xatf/xatf_init
#| NAME
#|   xatf_init -- Initalize Test cases
xatf_init() {
  #| USAGE
  #|   xatf_init
  #| DESCRIPTION
  #|   This function is meant to be called at the end of the shell
  #|   script used for testing.
  #|
  #|   It will scan for all the defined functions that begin with `xt_`
  #|   and it will create the relevant `_head` and `_body` functions.
  #|
  #|   Afterwards, it will use `xatf_auto_init_test_cases` to create
  #|   the required `atf_init_cases`.
  #|
  #|   The `_head` function is created from the main function by
  #|   scanning for : =<attr> "value"
  #|
  #|   The `_body` function will simply call the `xt_` function.
  #|****
  $_XATF_INITED && return
  _XATF_INITED=true

  local i fn
  for i in $(declare -F | awk '$1 == "declare" && $2 == "-f" && $3 ~ /^xt_/ { print $3 }')
  do
    atf_test_case $i
    fn="${i}_head() { :;
	$(declare -f $i \
	| awk '$1 == ":" && $2 ~ /^=/ {
	  $1 = "atf_set";
	  $2 = "'\''" substr($2,2) "'\''";
	  print
	}')
	}
	${i}_body() {
		${i} \"\$@\"
	}"
    eval "$fn"
  done
  #~ (declare -F ; declare -f xx_mytest_case_body)> log
  xatf_auto_init_test_cases
}

#
# test helper functions
#

#|****f* xatf/xtf
#| NAME
#|   xtf -- Sets strict `sh` modes and excute command
xtf() {
  #| USAGE
  #|   ( xtf cmd [cmd-args] )
  #| DESCRIPTION
  #|   Typically this function is meant to be called in a
  #|   sub shell, to execute a command with strict settings.
  #|****
  set -euf -o pipefail
  "$@"
}

#|****f* xatf/xtf_rc
#| NAME
#|   xtf_rc -- Executes a command with return code as output
xtf_rc() {
  #| USAGE
  #|   xtf_rc cmd
  #| DESCRIPTION
  #|   Executes a command, and returns the return code (on stdout)
  #|
  #|   The actual std output of the command is either discarded or
  #|   if `XTF_OUTPUT_TRACE` is `true`, the output is sent to
  #|   stderr
  #|****
  (
    if $XTF_OUTPUT_TRACE ; then
      exec 1>&2
    else
      exec >/dev/null 2>&1
    fi
    set -euf -o pipefail
    "$@"
  )
  echo "$?"
}

#|****f* xatf/xtf_ck
#| NAME
#|    xtf_ck --  Execute command like `xtf` but showing output to stderr
xtf_ck() {
  #| USAGE
  #|   xtf_ck cmd
  #| DESCRIPTION
  #|   Execute the given command.  The command and its output
  #|   are shown on stderr
  #|****
  echo "$* => $(xtf "$@")" 1>&2
}
