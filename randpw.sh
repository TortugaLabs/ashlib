#!/usr/bin/atf-sh

randpw() { #$ Generate random password
  #$ :usage: randpw [length]
  #$ :param length: password length
  #$ :output: random password of the specified length
  local chrs="1234567890abcdefghijklmnopqrstuvwxuyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#%^&*()-+_[]{};:,./<>?~'"
  local cc=$(expr length "$chrs")

  local cnt=32 i=''
  [ $# -gt 0 ] && cnt="$1"

  while [ $cnt -gt 0 ]
  do
    cnt=$(expr $cnt - 1)
    i="$i${chrs:$(expr $RANDOM % $cc):1}"
  done
  echo "$i"
}

###$_end-include
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_randpw_len() {
  : =descr "check is generated passwords meet lenght criteria"
  local q p
  for q in $(seq 4 4 128)
  do
    p="$(randpw $q)"
    [ $q -eq "$(expr length "$p")" ] || atf_fail "$q: $p length error"
  done
}

xt_randpw_rando() {
  : =descr "Randomness test"
  local a b q
  for q in $(seq 4 32)
  do
    a="$(randpw "$q")"
    b="$(randpw "$q")"
    [ "$a" = "$b" ] && atf_fail "$a == $b"
    :
  done
}


xatf_init
