#!/usr/bin/atf-sh

dehumanize() { #$ Convert values with suffix into bytes (or KBytes)
  #$ :usage: dehumanize [-k] value
  #$ :param -k: Optional.  Return the value in KBytes instead of bytes.
  #$ :param value: value (with suffix to compute)
  #$ :output: Will output the value in Bytes (or KBytes)
  local scale=''
  while [ $# -gt 0 ]
  do
    case "$1" in
    -k) scale='/1024' ;;
    *) break ;;
    esac
    shift
  done
  (
    if [ $# -eq 0 ] ; then
      cat
    else
      for i in "$@"
      do
	echo "$i"
      done
    fi
  )|   awk '
	/[0-9]$/ {print $1'"$scale"';next}
	/[tT]$/ {printf "%u\n", $1*(1024*1024*1024*1024)'"$scale"';next}
	/[gG]$/ {printf "%u\n", $1*(1024*1024*1024)'"$scale"';next}
	/[mM]$/ {printf "%u\n", $1*(1024*1024)'"$scale"';next}
	/[kK]$/{printf "%u\n", $1*1024'"$scale"';next}'
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
  ( xtf dehumanize -k 100 ) || atf_fail "ERROR#1"
  :
}

xt_run() {
  : =descr "Run options"
  for vv in "":1 -k:1024
  do
    opt=$(echo "$vv" | cut -d: -f1)
    adj=$(echo "$vv" | cut -d: -f2)

    for kk in \
	1234:0:1234 \
	25T:4:30223145490365729367654400 \
	8G:3:9223372036854775808 \
	2M:2:2199023255552 \
	3k:1:3145728
    do
      v=$(echo $kk | cut -d: -f1)
      p=$(echo $kk | cut -d: -f2)
      s=$(echo $kk | cut -d: -f3)

      m=1
      for i in $(seq 1 $p)
      do
	m=$(expr $m '*' 1024)
      done

      res=$(xtf dehumanize $opt $v)
      [ x"$(echo $res | awk "{print \$1 * $m * $adj}")" = x"$s" ] || atf_fail "ERR:$v,$p"
      :
    done
  done
}


xatf_init
