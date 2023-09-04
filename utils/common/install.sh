#
# Used to install scripts to current directory
#
###$_requires: die.sh

install_util() {
  [ $# -eq 0 ] && return 0
  local target=
  case "$1" in
    -i) [ $# -eq 1 ] && target=$(pwd) || target="$2" ;;
    --install=*) target="${1#--install=}" ;;
    --install) target="$(pwd)" ;;
    *) return 0
  esac

  [ -z "$target" ] && return 0
  [ ! -d "$target" ] && die -5 "$target: not a directory"

  target="$target/$(basename "$0")"
  [ -e "$target" ] &&  die -7 "$target: already exists!  Try re-binding instead."
  cp -av "$0" "$target"
  exit $?
}  

  
    
