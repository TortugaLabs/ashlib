#!/usr/bin/atf-sh

gitver() { #$ Determine the current version information from git
  #$ :usage: gitver _git-directory_
  #$ :param  git-directory: Directory to the git repository
  #$ :output: version information
  local dir="$1" ; shift
  if [ -d "$dir/.git" ] ; then
    if type git >/dev/null 2>&1 ; then
      # Git exists...
      local gitdir="--git-dir=$dir/.git" desc branch_name main_name
      main_name=$(git config --global init.defaultBranch)
      [ -z "$main_name" ] && main_name="master"
      desc=$(git $gitdir describe --dirty=,M 2>/dev/null)
      branch_name=$(git $gitdir symbolic-ref -q HEAD)
      branch_name=${branch_name##refs/heads/}
      branch_name=${branch_name:-HEAD}
      if [ "$main_name" = "$branch_name" ] ; then
	branch_name=""
      else
	branch_name=":$branch_name"
      fi
      echo $desc$branch_name
      return 0
    fi
  fi
  if [ -f "$dir.id" ] ; then
    cat "$dir.id"
    return 0
  fi
  if [ -f "$dir/.id" ] ; then
    cat "$dir/.id"
    return 0
  fi
  if [ -f "$dir/version.txt" ] ; then
    cat "$dir/version.txt"
    return 0
  fi
  echo 'Unknown'
  return 1
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh


xt_gitver() {
  : =descr "Test gitver"

  # Due to isolation this may need to configure thses
  for attr in init.defaultBranch:main user.email:nobody@nowhere user.name:$(whoami)
  do
    k=$(echo "$attr" | cut -d: -f1)
    v=$(echo "$attr" | cut -d: -f2)
    [ -z "$(git config --global "$k")" ] && git config --global "$k" "$v"
  done

  local randtag=$RANDOM
  (
    # exec >/dev/null 2>&1
    set -euf -o pipefail
    mkdir t.gitver
    cd t.gitver
    git init .
    echo $RANDOM > $RANDOM
    git add .
    git commit -m $RANDOM
    git tag -a $randtag -m $RANDOM
    local gv=$(gitver $(pwd))
    echo "randtag: $randtag"
    echo "gv: $gv"
    [ x"$randtag" = x"$gv" ] ||  exit $?
  )
  local rc="$?"
  rm -rf t.gitver
  [ $rc -gt 0 ] && atf_fail "$randtag failed"
  return $rc
}

xatf_init

