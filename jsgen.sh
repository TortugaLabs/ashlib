#!/usr/bin/atf-sh
# Based on: https://github.com/gekmihesg/ansible-openwrt/blob/master/files/wrapper.sh
# Copyright (c) 2017 Markus Weippert
# GNU General Public License v3.0 (see https://www.gnu.org/licenses/gpl-3.0.txt)

# TODO: test
# TODO: documentation

Q="\""
N="
"
T="	"


json_esc() {
  local in="$*" i=0 oo="" q="" len
  len=${#in}
  while [ $i -lt $len ]
  do
    local ch="${in:$i:1}"
    case "$ch" in
    [a-zA-Z0-9.~_/+-])
      oo="$oo$ch"
      ;;
    \"|\\)
      oo="$oo\\$ch"
      ;;
    *)
      if [ x"$ch" = x"$N" ] ; then
        oo="$oo\\n"
      elif [ x"$ch" = x"$(printf '\b')" ] ; then
        oo="$oo\\b"
      elif [ x"$ch" = x"$(printf '\t')" ] ; then
        oo="$oo\\t"
      elif [ x"$ch" = x"$(printf '\f')" ] ; then
        oo="$oo\\f"
      elif [ x"$ch" = x"$(printf '\r')" ] ; then
        oo="$oo\\r"
      else
	# TODO:handle non-printables
	oo="$oo$ch"
      fi
      ;;
    esac
    i=$(($i + 1))
  done
  echo "\"$oo\""
}

JSON_DATA=''
JSON_START_OBJ=false


json_init() {
  #~ echo "json_init: $*" 1>&2
  JSON_DATA=''
  JSON_START_OBJ=false
}
json_add_line() {
  if [ -z "$JSON_DATA" ] ; then
    JSON_DATA="$*"
  else
    if $JSON_START_OBJ ; then
      JSON_START_OBJ=false
      JSON_DATA="$JSON_DATA$N$*"
    else
      JSON_DATA="$JSON_DATA,$N$*"
    fi
  fi
}
json_add_object() {
  json_add_line "$(json_esc "$1"): {"
  JSON_START_OBJ=true
}
json_close_object() {
  JSON_DATA="$JSON_DATA${N}}$N"
}

json_add_boolean() {
  #~ echo "json_add_boolean: $*" 1>&2
  if [ ${2:-0} -eq 0 ] ; then
    json_add_line "$(json_esc "$1")": false
  else
    json_add_line "$(json_esc "$1")": true
  fi
}
json_add_string() {
  #~ echo "json_add_string: $*" 1>&2
  json_add_line "$(json_esc "$1")": "$(json_esc "$2")"
}
json_add_int() {
  json_add_line "$(json_esc "$1")": "$2"
}
json_dump() {
  #~ echo "json_dump: $*" 1>&2
  echo "{$N$JSON_DATA$N}"
}
json_cleanup() {
  #~ echo "json_cleanup: $*" 1>&2
  unset JSON_DATA
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_syntax() {
  :
}
xatf_init

