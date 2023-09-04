#!/usr/bin/atf-sh

html_enc() { #$ encode special characters into html entities
  #$ :usage: html_enc "text"
  #$ :usage: echo "text" | " html_enc
  #$ :param text: if specified, this is the text to be encoded.
  #$ :input: If no arguments are provided, stdin is read and used for the html encoded text
  #$ :output: HTML encoded text
  #$
  #$ Convert special characters into their HTML equivalents.
  #$ Specifically it will convert hte following characters:
  #$
  #$ * `&` -- `&amp;`
  #$ * `<` -- `&lt;`
  #$ * `>` -- `&gt;`
  #$ * `"` -- `&quot;`
  #$ * `'` -- `&#39;`
  local rules='s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
  if [ $# -eq 0 ] ; then
    sed "$rules"
  else
    echo "$@" | sed "$rules"
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

  ( xtf html_enc </dev/null ) || atf_fail "Failed compilation"
}

xt_runs() {
  : =descr run test

  input='and <strong>version</strong> <a href="/something?php=1&bob=2">yeah</a>'
  output='and &lt;strong&gt;version&lt;/strong&gt; &lt;a href=&quot;/something?php=1&amp;bob=2&quot;&gt;yeah&lt;/a&gt;'

  [ x"$(xtf html_enc "$input")" = x"$output" ] || atf "fail:args"
  [ x"$(echo "$input" | xtf html_enc)" = x"$output" ] || atf_fail "fail:stdin"
  :
}



xatf_init


