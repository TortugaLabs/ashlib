#!/usr/bin/atf-sh

pp_simple() { #$ Simple Pre-processor
  #$ :usage: pp_simple < input > output
  #$ :input: data to pre-process
  #$ :output: pre-processed data output
  #$
  #$ Read some textual data and output post-processed data.
  #$
  #$ Uses HERE_DOC syntax for the pre-processing language.
  #$ So for example, variables are expanded directly as `$varname`
  #$ whereas commands can be embedded as `$(command call)`.
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"
  local txt="$(echo "cat <<$eof" ; cat ; echo '' ;echo "$eof")"
  eval "$txt"
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_pp_simple() {
  : =descr "check"

  (xtf pp_simple < /dev/null ) || atf_fail "compile check"
  one="one"
  [ x"$(echo "$one" | xtf pp_simple)" = x"$one" ] || atf_fail "FAIL-1"
  two='$one + $one'
  two2="$one + $one"
  [ x"$(echo "$two" | xtf pp_simple)" = x"$two2" ] || atf_fail "FAIL-2"
  three='$(ls -l /etc)'
  thre2="$(ls -l /etc)"
  [ x"$(echo "$three" | xtf pp_simple)" = x"$thre2" ] || atf_fail "FAIL-3"

}

xatf_init
