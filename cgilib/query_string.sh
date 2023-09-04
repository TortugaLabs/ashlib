#!/usr/bin/atf-sh

###$_requires: query_string_raw.sh
###$_requires: urlencode.sh

query_string() { #$ parses QUERY_STRING and returns urldecoded results
  #$ :usage: query_string varname $QUERY_STRING
  #$ :param var_name: variable to extract
  #$ :param $QUERY_STRING: Query string to parse
  #$ :output: found variable, empty on error
  query_string_raw "$@" | urldecode
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

  . $(atf_get_srcdir)/urlencode.sh
  . $(atf_get_srcdir)/query_string_raw.sh

  ( xtf query_string a a </dev/null ) || atf_fail "Failed compilation"
}

xt_run() {
  : =descr run test

  . $(atf_get_srcdir)/urlencode.sh
  . $(atf_get_srcdir)/query_string_raw.sh

  for qstr in 'one=1&two=2&five&six' 'one=1;two=2;five&six'
  do
    for q in one:1 two:2 five: six:
    do
      r=$(echo $q | cut -d: -f2)
      q=$(echo $q | cut -d: -f1)
      [ x"$(xtf query_string "$q" "$qstr")" = x"$r" ] || atf_fail "Fail:$q|$qstr"
    done
  done
  :
}

xatf_init

