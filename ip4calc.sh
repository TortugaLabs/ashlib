#!/usr/bin/atf-sh
#$ IPv4 Calculations

#
# TODO: ipv4_broadcast addr netmask/prefix
# TODO: ipv4_network addr netmask/prefix
# TODO: ipv4_prefix netmask
  #~ awk -F. '{
      #~ split($0, octets)
      #~ for (i in octets) {
	  #~ mask += 8 - log(2**8 - octets[i])/log(2);
      #~ }
      #~ print "/" mask
  #~ }' <<< 255.255.255.240
#
# Other ops: wildcard, hostmin, hostmax, hosts/net

is_ipv4() { #$ Check if it is an IPv4 address
  #$
  #$ :usage: is_ipv4 str
  #$ :param str: string to check
  #$ :returns: true if IPv4 address, false otherwise.
  #$
  #$ This function only support quad dotted decimal notation
  #$
  if (echo "$1" | grep -q '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$') ; then
    local oIFS="$IFS" i
    IFS="." ; set - $1 ; IFS="$oIFS"
    for i in "$@"
    do
      [ "$i" -gt 255 ] && return 1
    done
    return 0
  fi
  return 1
}

cidr_to_netmask() { #$ convert CIDR prefix to netmask
  #$ :usage: cidr_to_netmask prefix
  #$ :param prefix: Prefix to convert
  #$ :output: calculated netmask
  #$
  #$ Based on https://gist.github.com/kwilczynski/5d37e1cced7e76c7c9ccfdf875ba6c5b
  value=$(( 0xffffffff ^ ((1 << (32 - $1)) - 1) ))
  echo "$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_cidr2netmask() {
  : =descr "CIDR to netmask"
  ( xtf cidr_to_netmask 24 ) || atf_fail "ERROR#1"

  for vv in 24:255.255.255.0 28:255.255.255.240 16:255.255.0.0 \
	    20:255.255.240.0
  do
    val=$(echo $vv | cut -d: -f1)
    res=$(echo $vv | cut -d: -f2)

    calc="$(xtf cidr_to_netmask $val)"

    if [ x"$calc" != x"$res" ] ; then
      atf_fail "ERR1:$val:\"$res\" != \"$calc\""
    fi
    :
  done
  :
}

xt_isipv4() {
  : =descr "Check is_ipv4"

  ( xtf is_ipv4 192.168.10.25 ) || atf_fail "ERROR#2"

  for vv in 127.20.5.1:0 127.45:1 299.54.56.52:1 ablcd:1
  do
    val=$(echo $vv | cut -d: -f1)
    drc=$(echo $vv | cut -d: -f2)

    rc=0
    ( xtf is_ipv4 $val ) || rc=$?
    [ $rc -eq $drc ] || atf_fail "ERR2:$val:$drc:$rc"
  done
  :
}


xatf_init
