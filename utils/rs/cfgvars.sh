#
# Configuration statements
#
export_vars=""
cfg() {
  local kv k v cmd overwrite=false

  while [ $# -gt 0 ]
  do
    case "$1" in
      -w|-f) overwrite=true ;;
      *) break ;;
    esac
    shift
  done

  for kv in "$@"
  do
    k="$(echo "$kv" | cut -d= -f1)"
    if $overwrite ; then
      eval v=\"\${$k:-}\"
      [ -z "$v" ] && v="$(echo "$kv" | cut -d= -f2-)"
    else
       v="$(echo "$kv" | cut -d= -f2-)"
    fi
    cmd="$k=$(shell_escape "$v");"
    export_vars="$export_vars$cmd"
    export "$k=$v"
  done
}

no_target() {
  # No target, runs in the current interpreter
  target=
  is_local=true
}

remote_target() {
  # remote target, runs via ssh
  target="$1"
  is_local=false
}
local_target() {
  # local target, runs via sudo or a separate shell
  target=""
  is_local=false
}

no_target
