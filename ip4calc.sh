#!/usr/bin/atf-sh
#$ IPv4 Calculations

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

xt_syntax() {
  : =descr "verify syntax..."
  ( xtf cidr_to_netmask 24 ) || atf_fail "ERROR#1"
  :
}

xt_run() {
  : =descr "Run options"

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
}


xatf_init
