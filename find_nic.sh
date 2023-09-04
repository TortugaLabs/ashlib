#!/usr/bin/atf-sh

find_nic() { #$ find a nic from a MAC address
  #$ :usage: find_nic mac
  #$ :param mac: mac address to find (xx:xx:xx:xx:xx)
  #$ :output: The device name that belongs to that mac address or empty
  #$
  #$ Given a mac address, returns the network interface to use in
  #$ ifconfig or other commands.
  local l_mac="$1"

  ip addr show | awk '
      BEGIN { devname=""; rc=1}
      $1 ~ /[0-9]+:$/ { devname=$2; }
      $1 == "link/ether" && $2 == "'"$l_mac"'" {
	print substr(devname,1,length(devname)-1);
	rc=0
      }
      END {
	exit rc;
      }
      '
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_findnic() {
  : =descr "find nic..."

  ( xtf find_nic "impossible" ) && atf_fail "IMPOSSIBLE1" || :
  [ -z "$(xtf find_nic "impossible")" ] || atf_fail "IMPOSSIBLE2"

  nics=$(
    ip a show | awk '
	BEGIN { devname="" }
	$1 ~ /[0-9]+:$/ { devname=$2; }
	$1 == "link/ether" {
	  print substr(devname,1,length(devname)-1) "," $2;
	}
    ')

  for nicmac in $nics
  do
    mac=$(echo $nicmac | cut -d, -f2)
    nic=$(echo $nicmac | cut -d, -f1)

    [ x"$(xtf find_nic "$mac")" = x"$nic" ] || atf_fail "$mac => $nic"
  done
}

xatf_init
