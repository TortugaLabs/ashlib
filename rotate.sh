#!/usr/bin/atf-sh

rotate() { #$ rotate log files
  #$ :usage: rotate [options] file
  #$ :param --count=n: number of archive files (defaults to 10)
  #$ :param --compress: commpress archive
  #$ :param file: file or files to rotate
  #$
  #$ Rotates a logfile file by subsequently creating up to
  #$ count archive files of it. Archive files are
  #$ named "file.number[compress-suffix]" where number is the version
  #$ number, 0 being the newest and "count-1" the oldest.
  local count=10 gz=

  while [ $# -gt 0 ]
  do
    case "$1" in
      --count=*) count=${1#--count=} ;;
      --compress) gz=.gz ;;
      --no-compress) gz= ;;
      *) break ;;
    esac
    shift
  done

  [ $# -ne 1 ] && return

  local f="$(readlink -f "$1")" t i j
  if [ -d "$f" ] ; then
    gz="" # Compression is not allowed for directories
  elif [ ! -s "$f" ] ; then
    return 0 # Skip missing or empty files
  fi

  j=$count
  while [ $j -gt 0 ]
  do
    i=$(expr $j - 1) || :
    if [ $j -eq $count ] ; then
      if [ -f "$f.$i$gz" ] ; then
	rm -f "$f.$i$gz"
      elif [ -d "$f.$i" ] ; then
	rm -rf "$f.$i"
      fi
    else
      [ -e "$f.$i$gz" ] && mv "$f.$i$gz" "$f.$j$gz"
    fi
    j=$i
  done

  if [ -d "$f" ] ; then
    mv "$f"  "$f.0"
    mkdir -m $(stat -c "%a" "$f.0") "$f"
    chown $(stat -c "%u:%g" "$f.0") "$f"
  else
    # We are trying to keep the file rotation time to a minimum
    t=$(mktemp -d -p "$(dirname "$f")")
    mv "$f" "$t/t"
    > "$f"
    # Restore file permissions and ownership
    chmod $(stat -c "%a" "$t/t") "$f"
    chown $(stat -c "%u:%g" "$t/t") "$f"

    # Archive file
    if [ -n "$gz" ] ; then
      gzip < "$t/t" > "$f.0$gz"
      chmod $(stat -c "%a" "$t/t") "$f"
      chown $(stat -c "%u:%g" "$t/t") "$f"
    else
      mv "$t/t" "$f.0"
    fi
    rm -rf "$t"
  fi
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_syntax() {
  : =descr "syntax check"

  ( xtf rotate ) || atf_fail "FAIL"
}

mk_f() {
  local count=$(expr $RANDOM % 500 + 1)

  (
    while [ $count -gt 0 ]
    do
      echo -n $RANDOM
      count=$(expr $count - 1)
    done
    :
  ) > "$1"
}
mk_d() {
  mkdir -p "$1"
  echo $RANDOM > "$1/$RANDOM"
}


xt_run() {
  : =descr "test run"

  for gz in "" --compress
  do
    for m in f d
    do
      [ $m = d ] && [ -n "$gz" ] && continue
      for count in "" 5 7 15
      do
	t=$(mktemp -p $(pwd) -d)
	rc=0
	(
	  set -euf -o pipefail

	  rotate $t/$m
	  [ $(ls -1 "$t" | wc -l) -ne 0 ] && atf_fail "FAIL:zero"

	  if [ -z "$count" ] ; then
	    gens=15
	    kount=""
	    max=11
	  else
	    gens=$(expr $count '*' 3 / 2)
	    kount=--count=$count
	    max=$(expr $count + 1)
	  fi

	  mk_$m $t/$m
	  for i in $(seq 1 $gens)
	  do
	    rotate $gz $kount $t/$m
	    mk_$m $t/$m
	    [ $(ls -1 $t | wc -l) -gt $max ] && exit 1
	    echo -n .
	  done

	  ls -1 "$t" | while read x
	  do
	    rm -rf "$t/$x"
	  done
	) || rc=$?
	rm -rf "$t"
	[ $rc -ne 0 ] && atf_fail "FAIL:$m:$count:"
	echo "OK:$m:$count:$gz:"
      done
    done
  done
}

xatf_init



