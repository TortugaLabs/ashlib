#!/usr/bin/atf-sh

parse_yaml() { #$ parse YAML formatted text
  #$ :usage: parse_yaml [--prefix=prefix] [files]
  #$ :param --prefix=PREFIX: output variables will be prefixed with PREFIX
  #$ :param files: files to parse, stdin if not specified
  #$
  #$ This is based on https://gist.github.com/briantjacobs/7753bf850ca5e39be409
  #$
  #$ Given simplified YAML document, it will output lines of the form
  #$
  #$ ```bash
  #$ yaml_key_path="value"
  #$ ```
  #$
  #$ Accepts hashes and lists.  With lists containing hashes
  #$ must start with an empty "-".
  local prefix=""
  while [ $# -gt 0 ]
  do
    case "$1" in
    --prefix=*) prefix=${1#--prefix=} ;;
    *) break ;;
    esac
    shift
  done

  local s
  local w
  local fs
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$@" |
  awk -F"$fs" '{
	  indent = length($1)/2;
	  if ($2 == "") {
	    if (indent in vname) {
	      two = vname[indent] + 1;
	    } else {
	      two = "0";
	    }
	  } else {
	    two = $2;
	  }
	  vname[indent] = two;
	  for (i in vname) {
	      if (i > indent) {delete vname[i]}
	  }
	  if (length($3) > 0) {
	      vn="";
	      for (i=0; i<indent; i++) {
		vn=(vn)(vname[i])("_");
	      }
	      printf("%s%s%s=\"%s\"\n", "'"$prefix"'",vn, two, $3);
	  }
	}'
}
###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_syntax() {
  ( xtf parse_yaml --prefix=YAML /dev/null ) || atf_fail "syntax"
}

xt_check() {
  local yaml=$(
    cat <<-_EOF_
	development:
	  adapter: mysql2
	  encoding: utf8
	  database: my_database
	  username: root
	  password: "abc"
	  apt:
	    - somepackage
	    - anotherpackage
	    - yeah: jf # this is not handled properly (should split into two lines)
	      complex: one
	      blah: two
	      hah: three
	      qox: blsd
	    - perfecto
	    - how
	    -
	      - yes
	      - no


	_EOF_
	)
  ( echo "$yaml" | xtf parse_yaml >/dev/null ) || atf_fail "CHK1"
  ( echo "$yaml" | xtf parse_yaml --prefix=YAML_ >/dev/null ) || atf_fail "CHK2"
  ( set -euf -o pipefail ; eval $(echo "$yaml" | xtf parse_yaml )) || atf_fail "CHK3"
  ( set -euf -o pipefail ; eval $(echo "$yaml" | xtf parse_yaml --prefix='local ' )) || atf_fail "CHK4"
  ( set -euf -o pipefail ; eval $(echo "$yaml" | xtf parse_yaml --prefix='YAML' )) || atf_fail "CHK5"

  eval $(echo "$yaml" | xtf parse_yaml --prefix='local ')
  local i j k kv prefix
  for kv in \
	development_adapter=mysql2 development_username=root development_apt_1=anotherpackage \
	development_apt_2_blah=two development_apt_4=how development_apt_5_1=no
  do
    i=$(echo "$kv" | cut -d= -f1)
    j=$(echo "$kv" | cut -d= -f2-)
    k=$(eval echo \${${i}:-})
    [ -z "$k" ] && atf_fail "Q:$i: missing"
    [ x"$k" != x"$j" ] && atf_fail "Q:$i: $j != $k"
  done
  :

}

xatf_init
