#!/usr/bin/atf-sh

###$_requires: pp.sh

pp_cmd() { #$ command line pp driver
  #$ :usage: pp_cmd [--output=output] -Iinclude-path -Dcmd file.m.ext ...
  if [ $# -eq 0 ] ; then
    echo "Usage: $0 {input.m.ext} ..."
    exit 1
  fi
  local output='' query=''
  #$
  #$ Implements a command line interface for the `pp` function
  #$
  #$ Input files of the form `file.m.ext` are then pre-processed and
  #$ the result is named `file.ext`.
  #$
  while [ $# -gt 0 ]
  do
    case "$1" in
    -o*)
      if [ -z "${1#-o}" ] ; then
	output="$2" ; shift
      else
	output="${1#-o}"
      fi
      ;;
    --output=*)
      output="${1#--output=}"
      ;;
    --query=*)
      query="${1#--query=}"
      [ -z "$output" ] && output="-"
      ;;
    -L)
      if [ $# -lt 2 ] ; then
        echo "No argument specified for -L"
        exit 2
      fi
      . "$2"
      shift
      ;;
    -L*)
      . "${1#-L}"
      ;;
    -I*)
      export PATH="$PATH:${1#-I}"
      ;;
    -D*)
      eval "${1#-D}"
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  #$ :param --output=file: write output to file
  #$ :param --query=query: uses query instead of stdin
  #$ :param -Lfile: load the given file (bash source)
  #$ :param -Idir: add the directory to PATH
  #$ :param -Dcommand: command is evaluated.  Usually for -Dkey=value assignemtns.
  #$ :param file.m.ext: input files
  local rc=0 done='[OK]' ppfilter="pp"

  if [ -n "$output" ]  ; then
    name=$(basename "$output" | tr A-Z a-z | sed -e 's/^\([_a-z0-9]*\).*$/\1/')
    [ x"$output" != x"-" ] && exec > "$output"

    if [ -n "$query" ] ; then
      set -
      if ! (export PATH="$(pwd):$PATH" ; echo "$query" | $ppfilter ) ; then
	rc=1
	done='[ERROR]'
      fi
    fi
    for input in "$@"
    do
      if [ x"$input" = x"-" ] ; then
	set -
	if ! (export PATH="$(pwd):$PATH" ; $ppfilter ) ; then
	  rc=1
	  done='[ERROR]'
	fi
      else
	[ $# -gt 1 ] && echo -n "$input " 1>&2
	if ! (
		name=$(basename "$input" | tr A-Z a-z | sed -e 's/^\([_a-z0-9]*\).*$/\1/')
		exec <"$input" ; export PATH="$(dirname "$input"):$PATH" ; pp
	     ) ; then
	  rc=1
	  done='[ERROR]'
	fi
      fi
    done
  else
    for input in "$@"
    do
      if [ ! -f "$input" ] ; then
	echo '' 1>&2
	echo "$input: not found" 1>&2
	rc=1
	done='[ERROR]'
	continue
      fi

      name=$(basename "$input" | tr A-Z a-z | sed -e 's/^\([_a-z0-9]*\).*$/\1/')
      output=$(echo "$input" | sed -e 's/\.m\.\([^.]*\)$/.\1/')
      [ x"$output" = x"$input" ] && output="$input.out"

      [ $# -gt 1 ] && echo -n "$input " 1>&2
      if ! ( exec <"$input" >"$output" ; export PATH="$(dirname "$input"):$PATH" ; $ppfilter ) ; then
	rc=1
	done='[ERROR]'
      fi
    done
  fi

  [ $# -gt 1 ] && echo "$done" 1>&2
  exit $rc
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh


xt_pp_cmd() {
  : =descr "check"

  . $(atf_get_srcdir)/pp.sh
  . $(atf_get_srcdir)/pp_include.sh
  include() { pp_include "$@"; }

  ( xtf pp_cmd --output=/dev/null $(atf_get_srcdir)/../LICENSE) || atf_fail "FAIL1"
}

xatf_init

