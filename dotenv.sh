#!/usr/bin/atf-sh
#$ Helps configuring dot environment files

###$_requires: cfv.sh

dotenv() { #$ Load dotenv files
  #$ :usage: dotenv [dir]
  #$ :param dir: directory to search for dotenv files, defaults to current directory
  #$
  #$ Loads configuration variables from dot env files.
  #$
  #$ It is recommend to define variables using `cfv` function
  #$ as that provides defaults without modifying any existing
  #$ previously defined environment variables.
  #$
  #$ Defines DOTENV_FILE with the file used.
  #$
  [ $# -eq 0 ] && set - "$(pwd)"
  local dir="$(echo "$1" | sed -e s'!/*$!!')" ; shift

  if [ -f "${dir}" ] ; then
    export DOTENV_FILE="$dir"
  elif [ -f "${dir}.env" ] ; then
    export DOTENV_FILE="${dir}.env"
  elif [ -f "${dir}/.env" ] ; then
    export DOTENV_FILE="${dir}/.env"
  else
    unset DOTENV_FILE
  fi
  if [ -n "${DOTENV_FILE:-}" ] ; then
    . "${DOTENV_FILE}"
  fi
  :
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
  t=$(mktemp -d)
  rc=0
  (
    set -euf -o pipefail
    cat > "$t/.env" <<-_EOF_
	export ZHOME=$HOME
	_EOF_
    dotenv "$t"
    [ "$DOTENV_FILE" = "$t/.env" ]
  ) || rc=$?
  rm -rf "$t"
  [ $rc -ne 0 ] && atf_fail "ERROR#$rc"
  :
}


xatf_init
