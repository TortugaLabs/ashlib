#!/usr/bin/atf-sh

commify() { #$ Format numbers with commas
  #$ :usage: commify value
  #$ :param value: value
  #$ :output: formatted value
  echo $1 | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

humanize_sz() { #$ Format numbers as friendly sizes
  #$ :usage: humaniz_sz [--bsz=scale] value
  #$ :param --bsz=scale: Optional.  block size
  #$ :param --dec=digits: Optional.  decimal points
  #$ :param value: value to format
  #$ :output: Will output value as a human readable string
  local scale=1 dec=1

  while [ $# -gt 0 ]
  do
    case "$1" in
      --bsz=*) scale=${1#--bsz=} ;;
      --dec=*) dec=${1#--dec=} ;;
      *) break ;;
    esac
    shift
  done
  if [ -z "$1" ] || [ "$1" -eq 0 ] ; then
    echo '0 B'
    return
  fi
  local sz=$(expr "$1" '*' $scale) i a b

  for i in \
    EB:1152921504606846976 \
    PB:1125899906842624 \
    TB:1099511627776 \
    GB:1073741824 \
    MB:1048576 \
    KB:1024
  do
    a=$(echo $i | cut -d: -f1)
    b=$(echo $i | cut -d: -f2)
    if [ $sz -gt $b ] ; then
      awk -vSZ=$sz.0 -vDIV=$b.0 'BEGIN {
	printf("%.'$dec'f '$a'\n", SZ / DIV);
	exit;
      }'
      return
    fi
  done
  echo "$sz B"
}


humanize_ti() { #$ Format numbers in seconds into human readable time intervals
  #$ :usage: humanize_ti [-m|-h|-d] value
  #$ :param -m: Optional.  value given in minutes
  #$ :param -h: Optional.  value given in hours
  #$ :param -d: Optional.  value given in days
  #$ :param value: value to format (in seconds unless option given)
  #$ :output: Will output value as a human readable string
  #|****
  local scale=1

  while [ $# -gt 0 ]
  do
    case "$1" in
      -m) scale=60 ;;
      -h) scale=3600 ;;
      -d) scale=86400 ;;
      *) break ;;
    esac
    shift
  done
  local c="$1" q="" t
  c=$(expr $c '*' $scale) || :
  local yr=$(expr $(expr 365 '*' 4 + 1) '*' $(expr 86400 / 4))

  if [ $c -ge $yr ] ; then
    t=$(expr $c / $yr)
    echo -n "$q$(commify $t) year"
    [ $t -ne 1 ] && echo -n s
    c=$(expr $c % $yr) || :
    q=", "
  fi
  if [ $c -ge 86400 ] ; then
    t=$(expr $c / 86400)
    echo -n "$q$t day"
    [ $t -ne 1 ] && echo -n s
    c=$(expr $c % 86400) || :
    q=", "
  fi
  if [ $c -ge 3600 ] ; then
    t=$(expr $c / 3600)
    echo -n "$q$t hour"
    [ $t -ne 1 ] && echo -n s
    q=", "
    c=$(expr $c % 3600)
  fi
  if [ $c -ge 60 ] ; then
    t=$(expr $c / 60)
    echo -n "$q$t minute"
    [ $t -ne 1 ] && echo -n s
    q=", "
    c=$(expr $c % 60) || :
  fi
  if [ $c -gt 0 ] ; then
    echo -n "$q$c second"
    [ $c -ne 1 ] && echo -n s
  fi
  echo
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
  ( xtf humanize_ti -h 10 ) || atf_fail "ERROR#1"
  ( xtf commify 293844 ) || atf_fail "ERROR#2"
  ( xtf humanize_sz 293144 ) || atf_fail "ERROR#3"

}

xt_run_ti() {
  : =descr "time intervals"
  for vv in \
    "-d:393804230:1,078,177 years, 80 days, 18 hours" \
    "-d:39380423:107,817 years, 263 days, 18 hours" \
    "-d:93804:256 years, 300 days" \
    "-d:993484:2,720 years, 4 days" \
    "-d:60:60 days" \
    "-d:360:360 days" \
    "-d:61:61 days" \
    "-h:393804230:44,924 years, 18 days, 14 hours" \
    "-h:39380423:4,492 years, 147 days, 23 hours" \
    "-h:93804:10 years, 256 days" \
    "-h:993484:113 years, 121 days, 22 hours" \
    "-h:60:2 days, 12 hours" \
    "-h:360:15 days" \
    "-h:61:2 days, 13 hours" \
    "-m:393804230:748 years, 268 days, 3 hours, 50 minutes" \
    "-m:39380423:74 years, 319 days, 23 minutes" \
    "-m:93804:65 days, 3 hours, 24 minutes" \
    "-m:993484:1 year, 324 days, 16 hours, 4 minutes" \
    "-m:60:1 hour" \
    "-m:360:6 hours" \
    "-m:61:1 hour, 1 minute" \
    ":393804230:12 years, 174 days, 22 hours, 3 minutes, 50 seconds" \
    ":39380423:1 year, 90 days, 13 hours, 23 seconds" \
    ":93804:1 day, 2 hours, 3 minutes, 24 seconds" \
    ":993484:11 days, 11 hours, 58 minutes, 4 seconds" \
    ":60:1 minute" \
    ":360:6 minutes" \
    ":61:1 minute, 1 second" \
    ":93804:1 day, 2 hours, 3 minutes, 24 seconds" \
    ":0:"
  do
    opt=$(echo "$vv" | cut -d: -f1)
    inp=$(echo "$vv" | cut -d: -f2)
    out=$(echo "$vv" | cut -d: -f3-)

    if [ $inp -eq 0 ] ; then
      calc=$(xtf humanize_ti 0)
      [ -z "$calc" ] || atf_fail "$opt:$inp=>$calc"
      continue
    fi

    if [ -z "$out" ] ; then
      echo "\"$opt:$inp:$( xtf humanize_ti $opt $inp)\" \\"
    else
      calc=$(xtf humanize_ti $opt $inp)
      [ x"$calc" = x"$out" ] || atf_fail "$opt:$inp=>$calc"
    fi
  done
}

xt_run_comma() {
  : =descr "commify"
  for vv in \
    "393804230:393,804,230" \
    "39380423:39,380,423" \
    "93804:93,804" \
    "993484:993,484" \
    "60:60" \
    "360:360" \
    "0:0" \
    393804230: \
    39380423: \
    93804: \
    993484: \
    60: \
    360: \
    0:
  do
    inp=$(echo "$vv" | cut -d: -f1)
    out=$(echo "$vv" | cut -d: -f2-)

    calc=$(xtf commify $inp)
    if [ -z "$out" ] ; then
      echo "\"$inp:$calc\" \\"
    else
      [ x"$calc" = x"$out" ] || atf_fail "$inp=>$calc not $out"
    fi
  done
}

xt_run_sz() {
  : =descr "humanize_sz"
  for vv in \
    "--dec=2:345349380424530:314.09 TB" \
    "--dec=2:39380424530:36.68 GB" \
    "--dec=2:393804230:375.56 MB" \
    "--dec=2:39380423:37.56 MB" \
    "--dec=2:93804:91.61 KB" \
    "--dec=2:993484:970.20 KB" \
    "--dec=2:60:60 B" \
    "--dec=2:360:360 B" \
    "--dec=0:345349380424530:314 TB" \
    "--dec=0:39380424530:37 GB" \
    "--dec=0:393804230:376 MB" \
    "--dec=0:39380423:38 MB" \
    "--dec=0:93804:92 KB" \
    "--dec=0:993484:970 KB" \
    "--dec=0:60:60 B" \
    "--dec=0:360:360 B" \
    "--bsz=1024:345349380424530:314.1 PB" \
    "--bsz=1024:39380424530:36.7 TB" \
    "--bsz=1024:393804230:375.6 GB" \
    "--bsz=1024:39380423:37.6 GB" \
    "--bsz=1024:93804:91.6 MB" \
    "--bsz=1024:993484:970.2 MB" \
    "--bsz=1024:60:60.0 KB" \
    "--bsz=1024:360:360.0 KB" \
    ":345349380424530:314.1 TB" \
    ":39380424530:36.7 GB" \
    ":393804230:375.6 MB" \
    ":39380423:37.6 MB" \
    ":93804:91.6 KB" \
    ":993484:970.2 KB" \
    ":60:60 B" \
    ":360:360 B" \
    ":0:0 B" \
    --dec=2:345349380424530: \
    --dec=2:39380424530: \
    --dec=2:393804230: \
    --dec=2:39380423: \
    --dec=2:93804: \
    --dec=2:993484: \
    --dec=2:60: \
    --dec=2:360: \
    --dec=0:345349380424530: \
    --dec=0:39380424530: \
    --dec=0:393804230: \
    --dec=0:39380423: \
    --dec=0:93804: \
    --dec=0:993484: \
    --dec=0:60: \
    --dec=0:360: \
    --bsz=1024:345349380424530: \
    --bsz=1024:39380424530: \
    --bsz=1024:393804230: \
    --bsz=1024:39380423: \
    --bsz=1024:93804: \
    --bsz=1024:993484: \
    --bsz=1024:60: \
    --bsz=1024:360: \
    :345349380424530: \
    :39380424530: \
    :393804230: \
    :39380423: \
    :93804: \
    :993484: \
    :60: \
    :360: \
    :0:

  do
    opt=$(echo "$vv" | cut -d: -f1)
    inp=$(echo "$vv" | cut -d: -f2)
    out=$(echo "$vv" | cut -d: -f3-)

    calc=$(xtf humanize_sz $opt $inp)
    if [ -z "$out" ] ; then
      echo "\"$opt:$inp:$calc\" \\"
    else
      [ x"$calc" = x"$out" ] || atf_fail "$inp=>$calc not $out"
    fi
  done
}


xatf_init
