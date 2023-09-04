#!/usr/bin/atf-sh

param() { #$ look-up key values from a params file
  #$ :usage: param "params-file" "key"
  #$ :param params-file: file with parameters
  #$ :param key: key to look-up
  #$ :output: configured value or empty string
  #$
  #$ This is a simple (quick and dirty) function to store configurable
  #$ parameters in a file.
  local src="$1" key="$2"
  awk '
    $1 == "'"$key"'" {
      $1="";
      print substr($0,2);
    }
  ' "$src"
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

  (
    set -euf -o pipefail
    param /dev/null none
  ) || atf_fail "Failed compiled"

}

xt_param() {
  [ x"$(xtf param $(atf_get_srcdir)/testlib/param.dat oneword)" = x"oneword" ] || atf_fail "Fail#one-word"
  [ x"$(xtf param $(atf_get_srcdir)/testlib/param.dat twowords)" = x"two words" ] || atf_fail "Fail#two-words"
  [ -z "$(xtf param $(atf_get_srcdir)/testlib/param.dat nowrods)" ] || atf_fail "Fail#no-words"
  :
}



xatf_init
