#!/usr/bin/atf-sh

###$_requires: query_string.sh

apihand() { #$ Handle JSON style API requests
  #$ :usage: apihand [options] cmd
  #$ :param --format=fmt: Use the given output format (do not get format from QUERY_STRING)
  #$ :param --no-query-format: Do not query format from QUERY_STRING
  #$ :param --query-format=varname: get output format from the variable`varname` in the QUERY_STRING.
  #$ :param --text: command stdout is assumed to be text
  #$ :param --json: (default) command stdout is JSON
  #$ :output: HTTP response
  #$
  #$ Calls the given command and provide the results in a suitable
  #$ request.  The output can be tweaked from the QUERY_STRING or
  #$ set specifically by a optional argument.  The default is
  #$ `application/json`.
  #$
  #$ Supported formats are:
  #$ * text/plain
  #$ * application/json
  #$ * application/javascript : this is JSON but for a JSONP response.
  #$
  #$ The status code of 500 is used to indicated failed runs.
  #$
  #$ If the output is set to `text/plain`, only the standard output
  #$ of the command is returned.
  #$
  #$ When using `application/json` format the output is a dictionary
  #$ with the following elements:
  #$ * status : is either "ok" or "error"
  #$ * return-code : numeric return code of the command.
  #$ * err-msg : output of stderr
  #$ * result : output of stdout.  The output is expected to be JSON
  #$   formatted.
  local format=application/json query_format=format text=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      --format=*) format=${1#--format=} ; query_format=false ;;
      --no-query-format) query_format='' ;;
      --query-format=*) query_format=${1#--query-format=} ;;
      --text) text=true ;;
      --json) text=false ;;
      --) shift ; break ;;
      *) break ;;
    esac
    shift
  done

  local t=$(mktemp) rcf=$(mktemp)
  # We do this weird thing in order to capture return code properly
  local stdout=$(("$@" 2>"$t" ) || echo $? >"$rcf")
  local rc=$(cat "$rcf") ; rm -f "$rcf" ; [ -z "$rc" ] && rc=0
  local err=$(cat "$t") ; rm -f "$t"

  if [ -n "$query_format" ]  ; then
    local c=$(query_string "$query_format" "${QUERY_STRING:-}")
    [ -n "$c" ] && format="$c"
  fi

  # Display results depending on the output format
  case "$format" in
  text/plain)
    [ $rc -ne 0 ] && echo "Status: 500"
    echo "Content-type: text/plain"
    echo ""
    echo "$stdout"
    ;;
  application/json|application/javascript)
    if [ $rc -ne 0 ] ; then
      local status='error'
      echo "Status: 500"
    else
      local status='ok'
    fi
    echo "Content-type: $format"
    echo ''
    [ "$(echo "$err" | wc -l)" -gt 1 ] && err="$(echo "$err" | sed -e 's/$/\\n/'  | tr -d '\n')"
    $text && stdout="\"$(echo "$stdout" | sed -e 's/$/\\n/'  | tr -d '\n')\""
    [ -z "$stdout" ] && stdout=null
    cat <<-_EOF_
	{
	  "status": "$status",
	  "return_code": $rc,
	  "err_msg": "$err",
	  "result": $stdout
	}
	_EOF_
    ;;
  *)
    cat <<-_EOF_
	Status: 500
	Content-type: text/plain

	Invalid output format: $format
	_EOF_
    ;;
  esac
  return $rc
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

. $(atf_get_srcdir)/query_string.sh
. $(atf_get_srcdir)/query_string_raw.sh
. $(atf_get_srcdir)/urlencode.sh

jqpre() {
  while read L
  do
    [ -z "$L" ] && break
  done
  cat | jq "$@"
}

xt_syntax() {
  : =descr "verify syntax..."

  ( xtf apihand --text true ) || atf_fail "Failed compilation"
}

xt_run() {
  : =descr "test apihand"

  for inrc in 1 $(expr $$ % 100) 0
  do
    [ $( xtf apihand exit $inrc | jqpre | jq -r '.return_code' ) -eq $inrc ] || atf_fail "ERR1:rc"
    [ $(xtf_rc apihand exit $inrc) -eq $inrc ] || atf_fail "apihand_rc"
  done

  arg=$$
  [ x"$(xtf apihand echo $arg | jqpre -r .result)" = x"$arg" ] || atf_fail "FAIL:simple"
  [ x"$(xtf apihand --json echo $arg | jqpre -r .result)" = x"$arg" ] || atf_fail "FAIL:simple json"
  [ x"$(xtf apihand --text echo $arg | jqpre -r .result)" = x"$arg" ] || atf_fail "FAIL:simple text"

  seq=$(seq 1 10)
  [ x"$(xtf apihand --text seq 1 10 | jqpre -r .result)" = x"$seq" ] || atf_fail "FAIL:multiline text"

  [ x"$(xtf apihand --format=text/plain echo $arg | jqpre .)" = x"$arg" ] || atf_fail "FAIL:text/plain"
  if ! (xtf apihand --format=application/javascript echo $arg | grep -q application/javascript) ; then
    atf_fail "FAIL:application/javascript"
  fi

  (
    export QUERY_STRING=format=text/plain
    [ x"$(xtf apihand echo $arg | jqpre -r .)" = x"$arg" ] || exit 1
    [ x"$(xtf apihand --no-query-format echo $arg | jqpre -r .result)" = x"$arg" ] || exit 2
  ) || atf_fail "FAIL:$?"
  :
}

xatf_init
