#!/usr/bin/atf-sh
#$ boolean check

#|****f* ashlib/yesno
#| NAME
#|   yesno --
yesno() { #$ boolean check
  #$ :usage: yesno value
  #$ :param value: test value.  Can either be the actual value or a variable name to test
  #$ :returns: true or false depending on the input
  #$
  #$ Translates the words:
  #$
  #$ * yes, true, on, 1 to a true value
  #$ * no, false, off, 0 to a false value
  #$
  #$ The checks are case insensitive.
        [ -z "${1:-}" ] && return 1

        # Check the value directly so people can do:
        # yesno ${VAR}
        case "$1" in
                [Yy]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
                [Nn]|[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
        esac

        # Check the value of the var so people can do:
        # yesno VAR
        # Note: this breaks when the var contains a double quote.
        local value=
        eval value=\"\$$1\"
        case "$value" in
                [Yy]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
                [Nn]|[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
                *) echo "\$$1 is not set properly" 1>&2; return 1;;
        esac
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
  ( xtf yesno 1 ) || atf_fail "ERROR#1"
  :
}

xt_run() {
  : =descr "Run options"

  for vv in yEs:0 no:1 TRUE:0 false:1 1:0 0:1 Y:0 n:1
  do
    val=$(echo $vv | cut -d: -f1)
    drc=$(echo $vv | cut -d: -f2)

    rc=0
    ( xtf yesno $val ) || rc=$?
    [ $rc -eq $drc ] || atf_fail "ERR1:$val:$drc:$rc"
    :

    (
      varname=v$RANDOM$$
      eval ${varname}=$val

      rc=0
      ( xtf yesno $varname ) || rc=$?
      [ $rc -eq $drc ] || atf_fail "ERR2:$val:$drc:$rc"
      :
    )
  done
}


xatf_init
