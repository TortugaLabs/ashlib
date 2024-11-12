#!/usr/bin/atf-sh
#$ Check resource locator types

is_url() { #$ check if this is a network URL
  #$ :usage: is_url path-to-check
  #$ :param path-to-check: string with path to check
  #$ :returns: true or false depending on input
  case "$1" in
  http://*|https://*|ftp://*) return 0;;
  *) return 1;;
  esac
}

is_localurl() { #$ check if this is a local URL
  #$ :usage: is_localurl path-to-check
  #$ :param path-to-check: string with path to check
  #$ :returns: true or false depending on input
  is_url "$@" && return 1 || return 0
}

is_abspath() { #$ check if this is absolute path
  #$ :usage: is_abspath path-to-check
  #$ :param path-to-check: string with path to check
  #$ :returns: true or false depending on input
  case "$1" in
  /*) return 0;;
  *) return 1;;
  esac
}

is_relpath() { #$ check if this is relative path
  #$ :usage: is_abspath path-to-check
  #$ :param path-to-check: string with path to check
  #$ :returns: true or false depending on input
  is_abspath "$1" && return 1 || return 0
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

  ( xtf is_url http://file ) || atf "ERROR#1"
  ( xtf is_localurl /file/name ) || atf "ERROR#2"
  ( xtf is_abspath /file/name ) || atf "ERROR#3"
  ( xtf is_relpath abc/kjc ) || atf "ERROR#4"
  :
}

xt_run() {
  : =descr "Run options"
  # case,url,local,abs,rel
  for case in \
      https://www.veqy.com/ryxw,0,1,1,0 \
      https://www.nuqo.com/ajzt,0,1,1,0 \
      https://www.kyza.com/efgh,0,1,1,0 \
      https://www.fyxo.com/uvwx,0,1,1,0 \
      https://www.xeqa.com/mnop,0,1,1,0 \
      https://www.jyzo.com/qrst,0,1,1,0 \
      /home/jyzo/Documents/fyxo.txt,1,0,0,1 \
      /usr/bin/nuqo/veqy,1,0,0,1 \
      /media/Music/kyza/ryxw.mp3,1,0,0,1 \
      /var/log/xeqa/ajzt.log,1,0,0,1 \
      /opt/Games/efgh/uvwx,1,0,0,1 \
      /tmp/Backup/mnop/qrst.zip,1,0,0,1 \
      ./Documents/fyxo.txt,1,0,1,0 \
      ../bin/nuqo/veqy,1,0,1,0 \
      ../../Music/kyza/ryxw.mp3,1,0,1,0 \
      ../../../log/xeqa/ajzt.log,1,0,1,0 \
      Games/efgh/uvwx,1,0,1,0 \
      Backup/mnop/qrst.zip,1,0,1,0 \
      ; do
    i=1
    val=$(echo "$case" | cut -d, -f1)
    for ts in is_url is_localurl is_abspath is_relpath
    do
      i=$(($i + 1))
      drc=$(echo "$case" | cut -d, -f$i)
      #~ echo "## $ts $val $drc"
      rc=0
      (  xtf $ts "$val" ) || rc=$?
      [ $rc -eq $drc ] || atf_fail "ERR $ts:$val:$drc:$rc"
    done
  done
  :
}


xatf_init
