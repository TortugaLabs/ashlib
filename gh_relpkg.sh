#!/usr/bin/atf-sh

gh_relpkg() { #$ get github release packages
  #$ :usage: gh_relpkg [options] owner repo [tag]
  #$ :param -v: verbose output
  #$ :param -q: quiet output
  #$ :param --api=url: change REST API end point
  #$ :param --assets: get assets url
  #$ :param --zip: get zipball url
  #$ :param --tar : get tarball url
  #$ :param owner : repo owner
  #$ :param repo : software repo
  #$ :param tag : optional release tag
  #$
  #$ Query Github and returns the asset files for the given
  #$ release.  If no release tag is given, it will default to "latest"
  local \
      baseurl="https://api.github.com/repos" \
      wget_opts="-q" rel=latest \
      jquery='.assets[].browser_download_url'


  while [ $# -gt 0 ]
  do
    case "$1" in
    -q) wget_opts="-q" ;;
    -v) wget_opts="-nv" ;;
    --api=*) baseurl=${1#--api=} ;;
    --assets) jquery='.assets[].browser_download_url' ;;
    --zip)  jquery='.zipball_url' ;;
    --tar)  jquery='.tarball_url' ;;
    *) break ;
    esac
    shift
  done
  if [ $# -lt 2 ] ; then
    echo "Need to specify owner and repo" 1>&2
    return 1
  elif [ $# -gt 3 ] ; then
    echo "Too many arguments" 1>&2
    return 2
  fi
  [ $# -gt 2 ] && rel="tags/$3"

  wget $wget_opts -O- "$baseurl/$1/$2/releases/$rel" | jq -r "$jquery"
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh


xt_check() {
  : =descr "check gh_pkgrel"

  if ! wget -q -O/dev/null https://github.com/ ; then
    echo "github.com missing... Skipping test" 1>&2
    return 0
  fi

  [ $(xtf gh_relpkg TortugaLabs swlib | wc -l) -gt 0 ] || atf_fail "swlib"
  ( xtf gh_relpkg --tar iliu-net MinigalNano | grep tarball ) || atf_fail "MinigalNano"
  [ $(xtf gh_relpkg -v iliu-net NeuSol 2>&1 | wc -l) -gt 1 ] || atf_fail "neusol"
  [ $(xtf gh_relpkg iliu-net pergamino 1.0.1 | wc -l) -gt 0 ] || atf_fail "pergamino"
  ( xtf gh_relpkg --zip iliu-net nanowiki 2.1.0-rel | grep zipball ) || atf_fail "nanowiki"
  set +x
}

xatf_init
