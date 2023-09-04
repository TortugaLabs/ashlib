#!/usr/bin/atf-sh
#$ URL encoding/decoding functions

urlencode() { #$ encode string according to URL escape rules
  #$ :usage: urlencode "string"
  #$ :param string: string to encode
  #$ :output: encoded string
  #$
  #$ Encode a "string" following URL encoding rules
  local l=${#1} i=0
  while [ $i -lt $l ]
  do
    local c=${1:$i:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      ' ') printf + ;;
      *) printf '%%%.2X' "'$c"
    esac
    i=$(expr $i + 1)
  done
}

urldecode() { #$ decode URL encoded strings
  #$ :usage: urldecode "string"
  #$ :param string: string to decode
  #$ :input: If no text is given as argument, urldecode will decode standard input.
  #$ :output: Decoded strings
  if [ $# -eq 0 ] ; then
    printf '%b\n' "$(sed 's/+/ /g; s/%\([0-9a-fA-F][0-9a-fA-F]\)/\\x\1/g;')"
  else
    local data=${1//+/ }
    printf '%b' "${data//%/\\x}"
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

  (
    set -euf -o pipefail
    urlencode abcdkf
    urldecode lakdjfs
    urlencode "$(dd if=/dev/urandom bs=128 count=1 | tr '\0' '\1')"
    echo ''
  ) || atf_fail "Failed compiled"

}

xt_encoding() {
  [ x"$(urlencode "https://www.notarealurl.com?id=50&name=namestring")" \
	= x"https%3A%2F%2Fwww.notarealurl.com%3Fid%3D50%26name%3Dnamestring" ] \
	|| atf_fail "Fail#1"
  [ x"$(urlencode "bar")" \
	= x"bar" ] \
	|| atf_fail "Fail#2"
  [ x"$(urlencode "some=weird/value")" \
	= x"some%3Dweird%2Fvalue" ] \
	|| atf_fail "Fail#3"
  # Support UTF-8 not there!
  #~ [ x"$(urlencode "Hello Günter")" \
	#~ = x"Hello%20G%C3%BCnter" ] \
	#~ || atf_fail "Fail#4"
  :
}

xt_decoding() {
  set -x
  [ x"$(urldecode "https%3A%2F%2Fwww.notarealurl.com%3Fid%3D50%26name%3Dnamestring")" \
	= x"https://www.notarealurl.com?id=50&name=namestring" ] \
	|| atf_fail "Fail#1"
  [ x"$(urldecode "bar")" \
	= x"bar" ] \
	|| atf_fail "Fail#2"
  [ x"$(urldecode "some%3Dweird%2Fvalue")" \
	= x"some=weird/value" ] \
	|| atf_fail "Fail#3"
  # Support UTF-8 not there!
  #~ [ x"$(urlencode "Hello Günter")" \
	#~ = x"Hello%20G%C3%BCnter" ] \
	#~ || atf_fail "Fail#4"
  :
}


xatf_init
