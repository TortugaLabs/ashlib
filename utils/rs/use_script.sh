
if [ $# -gt 0 ] && [ x"$1" = x"-s" ] ; then
  # Run using script...
  shift
  cmdline="$(shell_escape "$SHELL") $(shell_escape "$0")"
  for i in "$@"
  do
    cmdline="$cmdline $(shell_escape "$i")"
  done
  exec script -c "$cmdline" typescript.$(date +%F.%H.%M.%S)
fi

