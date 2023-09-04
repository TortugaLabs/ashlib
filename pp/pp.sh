#!/usr/bin/atf-sh

_pp_rewrite() {
  set +x
  local mode line eof="$1"
  mode='shell'
  while read -r line
  do
    if (echo "$line" | grep -q '^:[ \t]*##!') ; then
      : "found ##! cmode $mode"
      case "$mode" in
      shell)
	echo "$line" | sed -e 's/\(^:[ \t]*\)##!/\1/'
	;;
      heredoc)
	echo ":$eof"
	echo "$line" | sed -e 's/\(^:[ \t]*\)##!/\1/'
	mode="shell"
	;;
      esac
    else
      case "$mode" in
      shell)
	echo ":cat <<$eof"
	echo "$line"
	mode="heredoc"
	;;
      heredoc)
	echo "$line"
	;;
      esac
    fi
  done
  [ "$mode" = "heredoc" ] && echo ":$eof"
}

pp() { #$ Pre-processor
  #$ :usage: pp < input > output
  #$ :input: data to pre-process
  #$ :output: pre-processed data
  #$
  #$ Read some textual data and output post-processed data.
  #$
  #$ Uses HERE_DOC syntax for the pre-processing language.
  #$ So for example, variables are expanded directly as `$varname`
  #$ whereas commands can be embedded as `$(command call)`.
  #$
  #$ As additional extension, lines of the form:
  #$
  #$ ```typescript
  #$ ##! command
  #$ ```
  #$
  #$   Are used to include arbitrary shell commands.  These however
  #$   are executed in line (instead of a subshell as in `$(command)`.
  #$   This means that commands in `##!` lines can be used to define
  #$   variables, macros or include other files.
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"

  eval "$(sed -e 's/^/:/' | _pp_rewrite "$eof" | sed -e 's/^://' )"
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_pp() {
  : =descr "check"

  (xtf pp < /dev/null ) || atf_fail "compile check"
  one="one"
  [ x"$(echo "$one" | xtf pp)" = x"$one" ] || atf_fail "FAIL-1"
  two='$one + $one'
  two2="$one + $one"
  [ x"$(echo "$two" | xtf pp)" = x"$two2" ] || atf_fail "FAIL-2"
  three='$(ls -l /etc)'
  thre2="$(ls -l /etc)"
  [ x"$(echo "$three" | xtf pp)" = x"$thre2" ] || atf_fail "FAIL-3"

  input='
    ##! x1=onetwo
    $x1
    '
  output='
    onetwo'
  [ x"$(echo "$input" | xtf pp)" = x"$output" ] || atf_fail "FAIL-4"

}

xatf_init
