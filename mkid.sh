#!/usr/bin/atf-sh

mkid() { #$ create arbitrary id strings
  #$ :usage: _text_
  #$ :param text: text to convert into id
  #$ :output: Sanitized text
  #$
  #$ mkid accepts a string and sanitizes it so
  #$ that it can be used as a shell variable name
  echo "$*" | tr ' -' '__' | tr -dc '_A-Za-z0-9' \
  		| sed -e 's/^\([0-9]\)/_n\1/'
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_mkid() {
  : =descr "try random strings with mkid"

  local c p i
  for c in $(seq 1 500)
  do
  	p=$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | tr '\0' '.')
  	i=$(mkid "$p")
  	( xtf local ${i}=true ) || atf_fail "Failed convesions $i"
  done
}

xatf_init
