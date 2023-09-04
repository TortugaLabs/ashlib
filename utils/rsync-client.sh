#!/bin/sh
###$_requires: version.sh
set -euf -o pipefail
indexing=false
dryrun=false
info=true

while [ $# -gt 0 ]
do
  case "$1" in
    --index) indexing=true ;;
    --no-index) indexing=false ;;
    --dry-run) dryrun=true ;;
    --no-dry-run) dryrun=false ;;
    --info) info=true ;;
    --no-info) info=false ;;
    *) break;;
  esac
  shift
done

if [ $# -ne 5 ]  && [ $# -ne 4 ] ; then
  cat 1>&2 <<-_EOF_
	Usage:
	   $0 [options] module pwd-file srv src [dst]
	Options:
	--index : create index files
	--dry-run : do not transfer files
	--info : show statistics
	_EOF_
  exit 1
fi

module="$1"
pwdfile="$2"
srv="$3"
src="$4"
if [ $# -eq 5 ] ; then
  dst="$5"
else
  dst=""
fi

[ -n "$dst" ] && dst=$(echo "$dst" | sed -e 's!^/*!/!')
if [ ! -d "$src" ] ; then
  echo "$src: not found" 1>&2
  exit 1
fi

###$_requires: humanize.sh

$info && (
  echo "Started: $(date +"%Y-%m-%d %H:%M:%S") ==="
  echo "Source: $src"
  echo "module: $1"
  echo "server: $srv"
)
start=$(date +%s)

# create permissions
if $indexing ; then
  ipcdir=$(mktemp -d)
  trap "rm -rf $ipcdir" EXIT

  runpipe() {
    local fd="$1" ; shift
    mkfifo "$ipcdir/$fd"
    (
      "$@" < "$ipcdir/$fd" &
    )
    eval "exec $fd>"'$ipcdir/$fd'
    rm -f "$ipcdir/$fd"
  }

  specials() {
    tr '\n' '\0' | ( cd "$1" && cpio -o -H newc -0) | gzip -v > "$2"
  }

  caplist() {
    tr '\n' '\0' | ( cd "$1" && xargs -0 -r getcap ) | gzip -v > "$2"
  }

  faclist() {
    tr '\n' '\0' | ( cd "$1" && xargs -0 -r getfacl -p -n ) | gzip -v > "$2"
  }

  gzlist() {
    gzip -v > "$1"
  }

  # Index tree
  (
    fstree=$(readlink -f "$src")
    meta="$fstree/.meta"

    mkdir -p "$meta"
    runpipe 10 specials "$fstree" "$meta/specials.cpio.gz"
    runpipe 20 caplist "$fstree" "$meta/caps.txt.gz"
    runpipe 30 faclist "$fstree" "$meta/facl.txt.gz"
    runpipe 40 gzlist "$meta/filelist.txt.gz"

    find "$fstree" -print | sed -e "s!^$fstree/!!" -e "s!^$fstree\$!!" | (
    while read -r FPATH
    do
      [ -z "$FPATH" ] && continue
      [ x"$(echo $FPATH | cut -d/ -f1)" = x".meta" ] && continue
      [ -e "$fstree/$FPATH" ] || continue # OK, FPATH doesn't exist

      set - $(stat -c '%u:%g %a %h %i %s %F' "$fstree/$FPATH")
      [ $# -lt 6 ] && continue
      usrgrp="$1" ; mode="$2" ; hcnt="$3" ino="$4" sz="$5"; shift 5
      ftype="$*"

      case "$ftype" in
      directory|regular\ file|regular\ empty\ file)
	echo "$usrgrp $mode $hcnt $ino $FPATH" >&40
	echo "$FPATH" >&20
	echo "$FPATH" >&30
	;;
      *)
	echo "$FPATH" >&10
	;;
      esac
    done)
    #~ exec 10>&- 20>&- 30>&- 40>&-
  )

fi


# Rsync options:
#
#
# -a : archive
# -H : preseve hardlinks
# --delete : delete old files
# -z : compress
# -F : same as --filter='dir-merge /.rsync-filter'
# --no-perms : skip permissions
# --port=18873 : alternatie port
#
# -v : versbose
# --stats : summarize results

# Approach
# http://www.mikerubel.org/computers/rsync_snapshots/#Rsync
# Rotate snapshots, seed with latest from cron daily
# rsync to latest

# RSYNC_PASSWORD - environment variable to store password
export RSYNC_PASSWORD="$(cat "$pwdfile")"
rsync \
	$($dryrun && echo --dry-run) \
	--port=18873 \
	-aHz \
	-F \
	--no-perms \
	--delete \
	$($info && echo --stats) \
	"$src" "${module}@${srv}::${module}${dst}"
rc=$?
$info && echo $(humanize_ti $(expr $(date +%s) - $start))
$info && echo "EXIT: $rc"

exit $rc



# src=rsyncd/ ; srv=nd2 ; module=hassio ; RSYNC_PASSWORD=ziJ4Yi2o
  #~ server: nd2.localnet
  #~ port: 18873
  #~ target: hassio
  #~ username: hassio
  #~ password: ziJ4Yi2o
  #~ ssh_enabled: false

