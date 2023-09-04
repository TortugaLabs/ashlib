#!/usr/bin/atf-sh

post_data() { #$ ead the POST data
  #$ :usage: post_data
  #$ :input: stdin from web server to read POST request body
  #$ :output: Raw post data
  #$
  #$ Reads from stdin the body of a HTTP POST request.
  #~ local in_raw
  [ x"${REQUEST_METHOD:-}" != x"POST" ] && return
  [ -z "${CONTENT_LENGTH:-}" ] && return
  if [ "$CONTENT_LENGTH" -gt 0 ]; then
    head -c "$CONTENT_LENGTH"
    export CONTENT_LENGTH=0
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

  ( xtf post_data </dev/null ) || atf_fail "Failed compilation"
}

xt_runs() {
  : =descr run test

  body="$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM"
  export REQUEST_METHOD=POST CONTENT_LENGTH=$(expr length "$body")

  (
    result=$(echo "$body$body$body" | xtf post_data)
    [ "$result" = "$body" ] || exit 1
    result=$(export CONTENT_LENGTH=0 ; echo "$body$body$body" | xtf post_data)
    [ -z "$result" ] || exit 1
  ) || atf_fail "test1"
  :
}



xatf_init

