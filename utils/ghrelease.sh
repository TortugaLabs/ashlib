#!/bin/sh
###$_requires: version.sh
#
# Release script
#
set -euf -o pipefail

###$_requires: common/install.sh
###$_requires: stderr.sh

checks=".ghrelease-checks"
rc=false
github=false
gh_auth=false
if type gh >/dev/null 2>&1 ; then
  if gh auth status >/dev/null 2>&1 ; then
    gh_auth=true
    github=true
  fi
fi


while [ $# -gt 0 ]
do
  case "$1" in
    --rc|-t) rc=true ;;
    --rel|-r) rc=false ;;
    --gh|-g) github=true ;;
    --no-gh|-G) github=false ;;
    --) shift ; break ;;
    *) install_util "$@" ; break ;;
  esac
  shift
done

#@@@ ghrelease.1.md
#@ :version: <%VERSION%>
#@
#@ # NAME
#@
#@ **ghrelease** -- Perform a github release
#@
#@ # SYNOPSIS
#@
#@ **ghrelease** \[_options_] _version_
#@
#@ # DESCRIPTION
#@
#@ Perform activities related to creating a new release.  It will do the
#@ following:
#@
#@ 1. If a file named `.ghrelease-checks` exists it is executed.
#@    If it returns error, the process stops.
#@ 2. Makes sure that there are no uncommited changes.
#@ 3. Makes sure that there are commits since previous release
#@ 4. Creates a `version.h` or `VERSION` file with the _version_
#@ 5. Collect commit messages into release notes.
#@ 6. Commit and create a tag with _version_.
#@ 7. Use the github API to create a new release.
#@
#@ This is supposed to kick off a github workflow that can create
#@ release artifacts.
#@
#@ # OPTIONS
#@
#@ - **--\[no-]index** : Generate index data
#@ - **--rc|-t** : Create a release candidate (test release).  Can *not*
#@   be done on the _default_ branch.
#@ - **--rel|-r** : Create a release.  This is the default.  Can *only*
#@   be done on the _default_ branch.
#@ - **--\[no-\]gh**, -g or -G : Use the github API (this is the efault)
#@   Use `--no-gh` or `-G` to disable this.
#@ - **-i** \[_dir_] : install **ghrelease** to current directory or _dir_.
#@ - _version_ : version tag
#@ - **--purge** : Delete all pre-releases
#@
#@ # FILES
#@ - `.ghrelease-checks` : executable script used to do pre-release checkes
#@

if [ $# -lt 1 ] ; then
  cat <<-_EOF_
	Usage: $0 [options] version

	Options:
	* --rc|-t : create a release candidate (test release)
	* --rel|-r : create a release
	* --gh|-g : use github API
	* --no-gh|-G : do not use github API
	* version : version tag
	* -i [dir] : install $0 to current directory or [dir].

	If version is --purge, it will delete all pre-releases
	_EOF_
  gh release list
  exit 1
fi

if $github ; then
  if ! gh auth status ; then
    exit 2
  fi
fi

relid="$1" ; shift
if [ -n "${ORIG0:-}" ] ; then
  repodir="$(dirname "$(readlink -f "$ORIG0")")"
else
  repodir="$(dirname "$(readlink -f "$0")")"
fi
cd "$repodir"

git pull --tags # Make sure remote|local tags are in sync

if [ x"$relid" = x"--purge" ] ; then
  # Remove pre-release versions...
  if $github ; then
    gh release list | awk '$2 == "Pre-release" { print $1 }' | while read vtag
    do
      gh release delete $vtag --yes || :
      git tag -d $vtag || :
      git push --delete origin $vtag || :
    done
  else
    echo "You can only purge from github releases"
  fi
  exit
fi

if [ -n "$(git tag -l $relid)" ] ; then
  echo "Tag: \"$relid\" already exists!"
  gh release list
  exit 5
fi

cbranch=$(git rev-parse --abbrev-ref HEAD)
dbranch=$(basename "$(git rev-parse --abbrev-ref origin/HEAD)")

if $rc ; then
  echo "Release candidate: $relid"
else
  if [ x"$cbranch" != x"$dbranch" ] ; then
    echo "Current branch is \"$cbranch\""
    echo "Releases can only be done from the default branch: \"$dbranch\""
    echo "Switch to the default branch or use the --rc (release candidate) option"
    exit 2
  fi
fi

if [ -x "$checks" ] ; then
  "$(readlink -f "$checks")" $@ || die -13 "pre-release checks failed!"
else
  stderr ''
  stderr "Skipping pre-release checks"
  stderr "Create an executable script \"$checks\" to enable pre-release checks"
  stderr ''
fi

# Check for uncomitted changes
if [ -n "$(git status --porcelain)" ] ; then
  echo "Only run this on a clean checkout"
  echo ''
  git status
  exit 3
fi

if ptag=$(git describe --abbrev=0) ; then
  relnotes="$(git log "$ptag"..HEAD)" # --oneline
else
  relnotes="$(git log HEAD)" # --oneline
fi
[ -z "$relnotes" ] && die -4 "No commits since last release"

if [ -f "version.h" ] ; then
  vfile="version.h"
  vformat='const char version[] = "%s";\n'
else
  vformat='%s\n'
  vfile=VERSION
fi

printf "$vformat" "$relid" > "$vfile"
git add "$vfile"
git commit -m "$relid" "$vfile"
git tag -a "$relid" -m "$relid"
git push
git push --tags

gh release create \
	"$relid" \
	$($rc && echo --prerelease) \
	--target "$cbranch" \
	--title "$relid" \
	--notes "$relnotes"
