#!/usr/bin/atf-sh

http_resp() { #$ generate a HTTP response
  local status='' title='HTML msg' msg='none' lnks='' \
	location='' refresh='' toolbar="" xhead='' \
	content_type='text/html'
  #$ :usage: http_resp [options] msg
  #$ :param --status=[code]: status code
  #$ :param --content-type=mimetype: response type.  Defaults to text/html.
  #$ :param --location=[url]: used for page redirection
  #$ :param --refresh=[seconds, url]: refresh header
  #$ :param --title=[str]: title for document (only for text/html)
  #$ :param --link=[str,url]: add a link item which are displayed as a bullet list. (only for text/html)
  #$ :param --link=url: link to place in the link bullet list. (only for text/html)
  #$ :param --toolbar=[str,url]: add to a toolbar at the top the given link (only for text/html)
  #$ :param --toolbar=[url]: add to a toolbar at the top the given url (only for text/html)
  #$ :param --home=[url]: a home link to place on the toolbar. (only for text/html)
  #$ :param --head=[txt]: in text/html mode, this txt will be place in the `<head>` section of the response document.  Usually for injecting `<meta>`, `<style>` or `<script>` tags. If not in HTML mode, it will be added to the response header.
  while [ $# -gt 0 ]
  do
    case "$1" in
    --status=*) status=${1#--status=} ;;
    --title=*) title=${1#--title=} ;;
    --msg=*) msg=${1#--msg=} ;;
    --location=*) location=${1#--location=} ;;
    --refresh=*) refresh=${1#--refresh=} ;;
    --toolbar=*)
      local v=${1#--toolbar=}
      if (echo "$v" | grep -q ,) ; then
	local k=$(echo "$v" | cut -d, -f1)
	v=$(echo "$v" | cut -d, -f2-)
      else
        local k="$v"
      fi
      [ -n "$toolbar" ] && toolbar="$toolbar : "
      toolbar="$toolbar<a href=\"$v\">$k</a>"
      ;;
    --home=*)
      [ -n "$toolbar" ] && toolbar="$toolbar : "
      toolbar="$toolbar<a href=\"${1#--home=}\">home</a>"
      ;;
    --no-toolbar) toolbar='' ;;
    --link=*)
      local v=${1#--link=}
      if (echo "$v" | grep -q ,) ; then
        local k=$(echo "$v" | cut -d, -f1)
	v=$(echo "$v" | cut -d, -f2-)
      else
        local k="$v"
      fi
      lnks="$lnks<li><a href=\"$v\">$k</a></li>"
      ;;
    --no-links) lnks="" ;;
    --head=*) xhead=${1#--head=} ;;
    --content-type=*) content_type=${1#--content-type=} ;;
    --) shift; msg="$*" ; break ;;
    *)
      msg="$*"
      break
    esac
    shift
  done
  #$ :output: formatted response
  echo "Content-type: $content_type"
  [ -n "$status" ] && echo "Status: $status"
  [ -n "$location" ] && echo "Location: $location"
  [ -n "$refresh" ] && echo "Refresh: $refresh"
  if [ "$content_type" != "text/html" ] ; then
    [ -n "$xhead" ] && echo "$xhead"
    echo ''
    echo "$msg"
    return
  fi
  echo ''
  cat <<-_EOF_
	<!DOCTYPE html>
	<html lang="en">
	  <head>
	    <meta charset="utf-8">
	    <title>$title</title>
	    <meta name="viewport" content="width=device-width, initial-scale=1">
	_EOF_
  [ -n "$xhead" ] && echo "$xhead"
  [ -n "$refresh" ] && echo "<meta http-equiv=\"refresh\" content=\"$refresh\" />"
  cat <<-_EOF_
	  </head>
	  <body>
	    <h1>$title</h1>
	_EOF_
  [ -n "$toolbar" ] && echo "<hr>$toolbar<hr>"

  echo "$msg"

  if [ -n "$lnks" ] ; then
    echo "<ul>$lnks</ul>"
  fi
  echo "</body>"
  echo "</html>"
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

  ( xtf http_resp </dev/null ) || atf_fail "Failed compilation"
}

check_opt() {
  local opt="$1" outchk="$2" ; shift 2
  [ $# -eq 0 ] && set - $RANDOM$RANDOM$RANDOM$RANDOM$$
  local output="$(xtf http_resp "$opt" "$*")" || atf_fail "COMPILE:$opt"
  if ! (echo "$output" | grep -q "$outchk") ; then
    atf_fail "OUTPUT1:$opt:$outchk"
  fi
  [ x"$opt" == x"--" ] && return 0

  local output="$(xtf http_resp "$*")" || atf_fail "COMPILE1:$opt"
  if (echo "$output" | grep -q "$outchk") ; then
    atf_fail "OUTPUT2:$opt:"
  fi

  return 0
}

xt_run() {
  : =descr run test

  check_opt "--" body body
  check_opt --status=401 'Status: 401'
  check_opt --content_type=text/plain "text/plain"
  check_opt --location=http://localhost/ http://localhost/
  check_opt --refresh=5,http://localhost/ "Refresh: 5"
  check_opt --title=MY_TITLE "<title>MY_TITLE</title>"
  check_opt --link=one,http://something/ "<li><a href=\"http://something/\">"
  check_opt --link="http://example.com/" ">http://example.com/<"
  check_opt --toolbar=one,http://something/ "<a href=\"http://something/\">"
  check_opt --toolbar="http://example.com/" ">http://example.com/<"
  check_opt --home="http://home.com/" ">home<"
  check_opt --head='<style>' '<style>'
}

xatf_init
