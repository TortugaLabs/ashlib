#!/usr/bin/atf-sh

###$_requires: fixfile.sh

fixattr() { #$ update file attributes
  #$ :usage: fixattr [options] file
  #$ :param --mode=mode: Target file mode
  #$ :param --user=user: User to own the file
  #$ :param --group=group: Group that owns the file
  #$ :param file: file to modify.
  #$ :returns: Returns true if file was changed, false if no change was needed
  #$
  #$ This function ensures that the given `file` has the defined file modes,
  #$ owner user and owner groups.
  fixfile --no-content "$@"
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_check() {
  : =descr "check"
  (
    . $(atf_get_srcdir)/fixfile.sh
    xtf fixattr /etc/passwd || :
  ) || atf_fail "Compile"
}

xatf_init



