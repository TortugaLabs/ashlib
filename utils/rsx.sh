#!/bin/sh
#
# Copyright (c) 2023 Alejandro Liu
# Licensed under the MIT license:
#
# Permission is  hereby granted,  free of charge,  to any  person obtaining
# a  copy  of  this  software   and  associated  documentation  files  (the
# "Software"),  to  deal in  the  Software  without restriction,  including
# without  limitation the  rights  to use,  copy,  modify, merge,  publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons  to whom  the Software  is  furnished to  do so,  subject to  the
# following conditions:
#
# The above copyright  notice and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE  SOFTWARE  IS  PROVIDED  "AS  IS",  WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS  OR IMPLIED,  INCLUDING  BUT  NOT LIMITED  TO  THE WARRANTIES  OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR  OTHER LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT,  TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
set -euf -o pipefail

mydir=$(readlink -f "$(dirname "$0")")

###$_requires: shesc.sh
###$_requires: rs/use_script.sh
###$_requires: rs/cfgvars.sh
###$_requires: rs/envfiles.sh
###$_requires: rs/snippets.sh
###$_requires: common/install.sh
###$_requires: die.sh

# -- these functions are for use in loaded snippets ---

###$_requires: depcheck.sh
###$_requires: find_nic.sh
###$_requires: fixfile.sh
###$_requires: fixlnk.sh
###$_requires: is_mounted.sh
###$_requires: mkid.sh
###$_requires: on_exit.sh
###$_requires: param.sh
###$_requires: randpw.sh
###$_requires: retry.sh
###$_requires: stderr.sh
###$_requires: cgilib/urlencode.sh

fixattr() { fixfile --no-content "$@" ; }
# TODO: kvped solv_ln
# TODO:MAYBE: jobqueue refs rotate spk_enc extras/lvcfg macros/*

setx="${RS_SETX:-false}"
dryrun="${RS_DRYRUN:-false}"
vv="${RS_VERBOSE:-false}"

while [ $# -gt 0 ]
do
  case "$1" in
    -x|--set-x) setx=true ;;
    -t|--dry-run) dryrun=true ;;
    -v|--verbose) vv=true ;;
    -q|--quiet) vv=false ;;
    --no-target) no_target ;;
    --local) local_target ;;
    --target=*) remote_target ${1#--target=} ;;
    --*=*) cfg -f "${1#--}" ;;
    --) shift ; break ;;
    *) install_util "$@" ; break ;;
  esac
  shift
done

if [ -n "${RS_RCFILE:-}" ] ; then
  [ -f "${RS_RCFILE}" ] && . "${RS_RCFILE}"
fi

snippets_load

if [ $# -eq 0 ] ; then
  cat <<-__EOF__
	Usage: $0 [options] {snippet} [args]
	Options:
	  -s : create typescript (must always be the first argument)
	  -x : set -x
	  -v : verbose mode
	  -q : disables verbose mode
	  --dry-run : dry-run mode.  Show commands but don't execute
	  --no-target : run locally (in the same interpreter)
	  --local : run on localhost on a separated shell
	  --target=host : run remotely using ssh
	  --key=val : configure key value
	  -i [dir] : install $0 to current directory or [dir].

	Snippets:

	$(snippets_help)
	__EOF__
  exit 0
fi

snippet="$1" ; shift
# Make sure snippet name is valid
[ x"$snippet" != x"$(echo "$snippet" | tr -dc _A-Za-z0-9)" ] && die -83 "$snippet: invalid snippet name"

local_run() {
  local snfn="$1" ; shift
  if $dryrun ; then
    echo "$snfn" "$@"
    declare -f "$snfn"
  else
    rc=0
    ( $setx && set -x ; "$snfn" "$@" ) || rc=$?
    exit $rc
  fi
}

if $is_local ; then
  # Run in the current interpreter
  snfn=""
  for p in rs_ ps_
  do
    if declare -F "$p$snippet" >/dev/null ; then
      snfn="$p$snippet"
      break
    fi
  done
  [ -n "$snfn" ] && die -4 "$snippet: Only available in targetted runs"

  for p in ls_ sn_
  do
    if declare -F "$p$snippet" >/dev/null ; then
      snfn="$p$snippet"
      break
    fi
  done
  [ -z "$snfn" ] && die -86 "$snippet: Unknown snippet"

  $vv && stderr "Running $snfn"
  local_run "$snfn" "$@"
else
  # targetted run
  if declare -F "ls_$snippet" >/dev/null ; then
    $vv && stderr "Running in-place: ls_$snippet"
    local_run "ls_$snippet" "$@"
  else
    (declare -F "rs_$snippet" || declare -F "ps_$snippet"  || declare -F "sn_$snippet")>/dev/null || \
	die -22 "$snippet: no remote snippet"

    exec 3>&1 # Remember stdout...
    (
      echo 'set -o pipefail'
      echo 'set -euf'

      echo "$export_vars"
      declare -f

      $setx && echo "set -x"

      if declare -F "ps_$snippet" >/dev/null ; then
	# Pre-processed code
	$vv && stderr "Pre-processing with ps_$snippet"
	if $dryrun ; then
	  declare -f "ps_$snippet" | sed -e 's/^/#PS#/'
	else
	  sshout() { "$@" 1>&4; }
	  rcmd() { sshout echo "$@"; }
	  "ps_$snippet" "$@" 4>&1 1>&3
	fi
      fi
      snfn=""
      for f in rs_ sn_
      do
	if declare -F "$f$snippet" >/dev/null ; then
	  snfn="$f$snippet"
	  break
	fi
      done
      if [ -n "$snfn" ] ; then
	$vv && stderr "rexec: $snfn"
	echo -n "$snfn"
	for f in "$@"
	do
	  echo -n " $(shell_escape "$f")"
	done
	echo ''
      fi
      echo ''
      echo 'rc=$?'
      echo 'echo DONE: $rc'
      echo 'exit $rc'
    ) | (
      if $dryrun ; then
        exec cat
      else
	if [ -n "$target" ] ; then
	  $vv && stderr "Connecting to $target"
	  exec ssh \
		$([ -n "${SSH_AUTH_SOCK:-}" ] && [ -e "$SSH_AUTH_SOCK" ] && echo '-A') \
		"$target"
	else
	  if [ $(id -u) -eq 0 ] ; then
	    $vv && stderr "Spawning $SHELL -l "
	    exec "$SHELL" -l
	  else
	    stderr "Running sudo $SHELL -l"
	    exec sudo "$SHELL" -l
	  fi
	fi
      fi
    )
  fi
fi
