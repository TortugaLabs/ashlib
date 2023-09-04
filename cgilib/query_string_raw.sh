#!/usr/bin/atf-sh

query_string_raw() { #$ parses QUERY_STRING
  #$ :usage: query_string_raw varname $QUERY_STRING
  #$ :param var_name: variable to extract
  #$ :param $QUERY_STRING -- Query string to parse
  #$ :output: found variable, empty on error
  local var="$1" ; shift
  local qstr=$(echo "$*" | tr ';' '&') keyw
  if [ -n "$qstr" ] ; then
    export IFS="&"
    for keyw in ${qstr}
    do
      if ( echo "$keyw" | grep -q '=') ; then
	local \
	  key="$(echo "$keyw" | cut -d= -f1)" \
	  val="$(echo "$keyw" | cut -d= -f2-)"
	if [ x"$key" = x"$var" ] ; then
	  echo "$val"
	fi
      fi
    done
  fi
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

  ( xtf query_string_raw a a </dev/null ) || atf_fail "Failed compilation"
}

xt_run() {
  : =descr run test

  for qstr in 'one=1&two=2&five&six' 'one=1;two=2;five&six'
  do
    for q in one:1 two:2 five: six:
    do
      r=$(echo $q | cut -d: -f2)
      q=$(echo $q | cut -d: -f1)
      [ x"$(xtf query_string_raw "$q" "$qstr")" = x"$r" ] || atf_fail "Fail:$q|$qstr"
    done
  done
  :
}



xatf_init

