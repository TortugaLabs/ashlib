#!/usr/bin/atf-sh
#$ Perform comparisons using version semantics

v_gt() { #$ version greater than comparison
  #$ :usage: v_gt verstr1 verstr2
  #$ :param verstr1: first version string to compare
  #$ :param verstr2: second version string to compare
  #$ :returns: true or false depending on the input.  Returns 128 on error.
  #$
  #$ Compares two values interpreted as string using the `sort`
  #$ command `-V` option.
  [ $# -ne 2 ] && return 128
  test "$(echo "$@" | tr ' ' '\n'|sort -V|head -n 1)" != "$1"
}

v_le() { #$ version less or equal comparison
  #$ :usage: v_le verstr1 verstr2
  #$ :param verstr1: first version string to compare
  #$ :param verstr2: second version string to compare
  #$ :returns: true or false depending on the input.  Returns 128 on error.
  #$
  #$ Compares two values interpreted as string using the `sort`
  #$ command `-V` option.
  [ $# -ne 2 ] && return 128
  test "$(echo "$@" | tr ' ' '\n'|sort -V|head -n 1)" == "$1"
}

v_lt() { #$ v_lt -- version less than comparison
  #$ :usage: v_lt verstr1 verstr2
  #$ :param verstr1: first version string to compare
  #$ :param verstr2: second version string to compare
  #$ :returns: true or false depending on the input.  Returns 128 on error.
  #$
  #$ Compares two values interpreted as string using the `sort`
  #$ command `-V` option.
  [ $# -ne 2 ] && return 128
  test "$(echo "$@" | tr ' ' '\n'|sort -rV|head -n 1)" != "$1"
}

v_ge() { #$ version greater or equal comparison
  #$ :summary: v_ge verstr1 verstr2
  #$ :param verstr1: first version string to compare
  #$ :param verstr2: second version string to compare
  #$ :returns: true or false depending on the input.  Returns 128 on error.
  #$
  #$
  #$ Compares two values interpreted as string using the `sort`
  #$ command `-V` option.
  [ $# -ne 2 ] && return 128
  test "$(echo "$@" | tr ' ' '\n'|sort -rV|head -n 1)" == "$1"
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
  ( xtf v_gt 1.0 0.5 ) || atf_fail "ERROR#1"
  ( xtf v_le 1.0 1.5 ) || atf_fail "ERROR#2"
  ( xtf v_lt 1.0 2.5 ) || atf_fail "ERROR#3"
  ( xtf v_ge 1.0 0.5 ) || atf_fail "ERROR#4"
  :
}

xt_run() {
  : =descr "Run options"
  local t=0 f=1

  for vv in \
      gt:2.5:3.0:$f gt:4.5.9:2.3.8:$t gt:3.3:3.3:$f \
      le:5.5:3.0:$f le:1.5.9:2.3.8:$t le:3.3:3.3:$t \
      lt:4.5:3.0:$f lt:4.5.9:8.3.8:$t lt:3.3:3.3:$f \
      ge:2.5:3.0:$f ge:4.5.9:2.3.8:$t ge:3.3:3.3:$t
  do
    op=$(echo $vv | cut -d: -f1)
    v1=$(echo $vv | cut -d: -f2)
    v2=$(echo $vv | cut -d: -f3)
    r=$(echo $vv | cut -d: -f4)

    rc=0
    ( xtf v_$op $v1 $v2 ) || rc=$?
    [ $rc -eq $r ] || atf_fail "ERR:$vv:$rc"
  done
}


xatf_init
