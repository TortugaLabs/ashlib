#!/usr/bin/atf-sh

solv_ln() { #$ Resolves symbolic links so they are relative paths
  #$ :usage: solv_ln target linkname
  #$ :param target: target path (as used with `ln -s`)
  #$ :param linkname: link to be created
  #$ :output: Relative path from linkname to target
  #$ :returns: false on error, true on success.
  #$
  #$ Given two paths in the same format as creating a symbolic link
  #$ using `ln -s`, it will return a relative path from `linknam` to
  #$ `target` as if `linknam` was a symbolic link to `target`.
  #$
  #$ `target` and `linkname` can be provided as absolute or relative
  #$ paths.
  local target="$1" linknam="$2"

  [ -d "$linknam" ] && linknam="$linknam/$(basename "$target")"

  local linkdir=$(readlink -f "$(dirname "$linknam")")
  local targdir=$(readlink -f "$(dirname "$target")")

  linkdir=$(echo "$linkdir" | sed 's!^/!!' | tr ' /' '/ ')
  targdir=$(echo "$targdir" | sed 's!^/!!' | tr ' /' '/ ')

  local a='' b=''

  while :
  do
    set - $linkdir ; a="$1"
    set - $targdir ; b="$1"
    [ $a != $b ] && break
    set - $linkdir ; shift ; linkdir="$*"
    set - $targdir ; shift ; targdir="$*"
    [ -z "$linkdir" ] && break;
    [ -z "$targdir" ] && break;
  done

  if [ -n "$linkdir" ] ; then
    set - $linkdir
    local q=""
    linkdir=""
    while [ $# -gt 0 ]
    do
      shift
      linkdir="$linkdir$q.."
      q=" "
    done
  fi
  echo $linkdir $targdir $(basename $target) | tr '/ ' ' /'
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_check() {
  : =descr "check"
  (
    xtf solv_ln /usr/bin /etc/passwd || :
  ) || atf_fail "Compile"
}

xt_run() {
  : =descr "Run checks"
  [ x"$( xtf solv_ln abc cba )" = x"abc" ] || atf_fail "ERR#1"
  [ x"$( xtf solv_ln /usr/bin/pwd /usr/local/bin/abc )" = x"../../bin/pwd" ] || atf_fail "ERR#2"
  [ x"$( xtf solv_ln /usr/local/bin/ls /usr/bin/xyz )" = x"../local/bin/ls" ] || atf_fail "ERR#3"
  :
}

xatf_init
