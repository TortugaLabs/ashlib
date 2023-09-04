#
# Run Snippets
#
# Snippets are functions of the form:
#
# rs_XXXX : Remote Snippet : runs on the target
# ps_XXXX : Pre-processed Snippet : runs locally but output send to target to be executed
# ls_XXXX : Local snippet : always run locally
# sn_XXXX : snippet that may run remote or local depending on the mode
#

snippets_inv() {
  declare -F \
	| grep -E '^declare -f (rs|ps|ls|sn)_[_A-Za-z][A-Za-z0-9]*' \
	| sed -e 's/^declare -f [a-z][a-z]_//' \
	| sort -u
}

snippets_fns() {
  local i f="$1"
  (for i in rs ps ls sn
  do
    declare -F ${i}_${f} || :
  done) |  xargs
}

snippets_load() {
  local i
  for i in $(find "$mydir" -maxdepth 1 -mindepth 1 -name '*.sh')
  do
    [ ! -f "$i" ] && continue
    grep -q -E '^\s*(rs|ps|ls|sn)_[_A-Za-z][A-Za-z0-9]*\(' "$i" || continue
    $vv && stderr "Loading $i"
    . "$i"
  done

  local err="" c
  for s in $(snippets_inv)
  do
    c=0
    declare -F sn_${s} > /dev/null && c=$(expr $c + 1)
    declare -F ls_${s} > /dev/null && c=$(expr $c + 1)
    (declare -F rs_${s} || declare -F ps_${s}) >/dev/null && c=$(expr $c + 1)
    [ $c -gt 1 ] && err="$err $s"
  done
  [ -n "$err" ] && die -45 "Conflicting snippet definitions: $err"
  $vv && stderr "Snippets: $(snippets_inv | wc -w)"
  :
}

snippets_help() {
  local sn fs f msg
  snippets_inv | while read sn
  do
    fs=$(snippets_fns "$sn")
    msg=$(
      (for f in $fs
      do
	declare -f "$f" \
		  | awk '$1 == ":" && $2 == "DESC" { $1=""; $2=""; print ; }' \
		  | sed -e 's/^  //' -e 's/;$//'
      done) | uniq
    )
    if [ -n "$msg" ] ; then
      if [ $(echo "$msg" | wc -l) -eq 1 ] ; then
        echo "* $sn : $msg ($fs)"
      else
        echo "$msg" | (
	  fmt="* $sn : %s ($fs)"
	  while read ln
	  do
	    printf "$fmt\n" "$ln"
	    fmt="  %s"
	  done
	)
      fi
    else
      echo "* $sn : $fs"
    fi    
  done
}   

#
# These two are built-in snippets
#
# Essentially test snippets
#
rs_ping() {
  : DESC Check connectivity
  echo "Hello world $(hostname)"
}
sn_uptime() {
  : DESC display local uptime
  uptime
}

#~ sn_fake1() {
  #~ : DESC this is desc
  #~ ugie
  #~ dougie
#~ }


#~ rs_boo() {
  #~ : DESC just a thing
  #~ another thing
#~ }

#~ ps_boo() {
  #~ : DESC blah blah
  #~ blah
  #~ ble
#~ }

#~ ls_foo() {
  #~ : DESC bo bo
  #~ blah
#~ }

#~ rs_blah() {
  #~ yeah yea
#~ }

#~ sn_blah() {
  #~ yow

#~ }

#~ set -euf -o pipefail
#~ snippets_help
#~ mydir=$HOME/ww/qcontainers

#~ set -x
#~ snippets_load




