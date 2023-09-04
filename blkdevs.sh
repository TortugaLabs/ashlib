#!/usr/bin/atf-sh

bd_in_use() { #$ List block devices in use
  #$ :usage: bd_in_use
  #$ :output: List of disk devices in use
  #$
  #$ Uses `lsblk` to determina which disc's are currently in use.
  lsblk -n -o NAME,FSTYPE,MOUNTPOINTS --raw | while read name fstype mounted
  do
    [ ! -b /dev/$name ] && continue
    [ -z "$fstype" ] && continue
    if [ -n "$mounted" ] ; then
      echo "mounted $name"
    elif [ -n "$fstype" ] ; then
      case "$fstype" in
      crypto*|LVM2*)
	echo "$fstype $name"
	;;
      esac
    fi
  done | awk '
	{
	  if (match($2,/[0-9]p[0-9]+$/)) {
	    sub(/p[0-9]+$/,"",$2)
	    mounted[$2] = $2
	  } else {
	    sub(/[0-9]+$/,"",$2)
	    mounted[$2] = $2
	  }
	}
	END {
	  for (i in mounted) {
	    print mounted[i]
	  }
	}
  '
}
bd_list() { #$ List available block devices
  #$ :usage: bd_list
  #$ :output: List of block devices
  #$
  #$ Create a list of all available physical block devices.
  find /sys/block -mindepth 1 -maxdepth 1 -type l -printf '%l\n' | grep -v '/virtual/' | while read dev
  do
    dev=$(basename "$dev")
    [ ! -e /sys/block/$dev/size ] && continue
    [ $(cat /sys/block/$dev/size) -eq 0 ] && continue
    echo $dev
  done
}


bd_unused() { #$ list unused block devices
  #$ :usage: bd_unused
  #$ :output: List of unused block devices
  #$
  #$ Create a list of all physical block devices that are not being
  #$ used.  i.e. not mounted and not used in compound device.

  local used_devs=$(bd_in_use) i j
  for i in $(bd_list)
  do
    for j in $used_devs
    do
      [ "$i" = "$j" ] && continue 2
    done
    echo "$i"
  done
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh


xt_check() {
  : =descr "check syntax"

  #
  # Note that these tests essentially are only checking for syntax
  # errors, as it is not easy to check output in a system independant
  # manner.

  ( xtf bd_in_use ) || atf_fail "bd_in_use"
  ( xtf bd_list ) || atf_fail "bd_list"
  ( xtf bd_unused ) || atf_fail "bd_unused"
}

xatf_init
