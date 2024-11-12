#!/usr/bin/atf-sh

fixfile() { #$ Modify files in-place
  #$ :usage: fixfile [options] file
  local mode= user= group= backupdir= backupext="~" filter=false mkdir=false encoded=false content=true dryrun=false
  #$
  #$ By default, modified files will be first backed up to a file with ~ extension.
  #$ The following options are available:
  #$
  #$ :param --dry-run: perform a trial run with no changes made
  #$ :param --nobackup: disable creation of backups
  #$ :param --backupext=ext: Backups are created by adding ext.  Defaults to "~".
  #$ :param --no-content: only change metadata (mode, group, ownership)
  #$ :param --filter: Use filter mode.  The stdin is used as an script that will modify stdin (current file) and the stdout is used as the new contents of the file.
  #$ :param --decode: input is considered to be gzippped+base64 encoded data
  #$ :param --mode=mode: mode to set permissions to.
  #$ :param --user=user: set ownership to user
  #$ :param --group=group: set group to group
  #$ :param -D|--mkdir: if specified, containing directory is created if doesn't exist.
  #$ :param --: stop processing arguments
  #$ :param file: file to create or modify
  while [ $# -gt 0 ]
  do
    case "$1" in
      --nobackup) backupext= ;;
      --backupext=*) backupext=${1#--backupext=} ;;
      --filter) filter=true ;;
      --decode) encoded=true ;;
      --no-content) content=false ;;
      --mode=*) mode=${1#--mode=} ;;
      --user=*) user=${1#--user=} ;;
      --group=*) group=${1#--group=} ;;
      --dry-run) dryrun=true ;;
      -D|--mkdir) mkdir=true ;;
      --) shift ; break ;;
      -*)  echo "Invalid option: $1" 1>&2 ; return 6 ;;
      *) break ;;
    esac
    shift
  done
  #$
  #$ Files are modified in-place only if the contents change.  This means
  #$ time stamps are kept accordingly.
  #$
  #$ <stdin> will be used as the contents of the new file unless --filter
  #$ is specified.  When in filter mode, the <stdin> is a shell script
  #$ that will be executed with <stdin> is the current contents of the
  #$ file and <stdout> as the new contents of the file.
  #$
  #$ Again, file is only written to if its conents change.
  #$
  if $encoded && $filter ; then
    echo "Can not specify --filter and --decode!" 1>&2
    return 2
  fi
  if ! $content ; then
    if ($encoded || $filter) ; then
      echo "Can not specify --filter or --decode with --no-content!" 1>&2
      return 3
    fi
  fi

  if [ $# -eq 0 ] ; then
    echo "No file specified" 1>&2
    return 5
  fi
  local file="$1" ; shift
  [ $# -gt 0 ] && echo "Ignoring additional options: $*" 1>&2

  if [ -z "$group" ] && [ -n "$user" ] ; then
    # Check if user == {user}:{group}
    eval $(
	echo "$user" | (
	    IFS=:
	    a="" ; b=""
	    read a b
	    [ -z "$b" ] && return
	    echo "user='$a' ; group='$b'"
	)
    )
  fi

  local msg= otxt="" ntxt="" tmpfile=""

  if [ -f "$file" ] ; then
    if $encoded ; then
      # Handled binary files...
      otxt="$(md5sum "$file" | awk '{print $1}')"
    else
      otxt=$(sed 's/^/:/' "$file")
    fi
  else
    if ! $content ; then
      echo "$file: does not exist (can not create)" 1>&2
      return 4
    fi
    if $mkdir && [ ! -d "$(dirname "$file")" ] ; then
      $dryrun || mkdir -p "$(dirname "$file")"
      [ -n "$user" ] && $dryrun || chown "$user" "$(dirname "$file")"
      [ -n "$group" ] && $dryrun || chgrp "$group" "$(dirname "$file")"
    fi
  fi

  if $filter ; then
    # Stdin is not contents but actually is a filter script
    local incode="$(cat)"
    if [ -f "$file" ] ; then
      ntxt="$(cat "$file")"
    else
      ntxt=""
    fi
    ntxt=$(echo "$ntxt" | (eval "$incode" )| sed 's/^/:/' )
  elif $encoded ; then
    tmpfile=$(mktemp -p "$(dirname "$file")")
    base64 -d | gunzip > "$tmpfile"
    ntxt=$(md5sum "$tmpfile" | awk '{print $1}')
  else
    $content && ntxt=$(sed 's/^/:/')
  fi

  if $content && [ x"$otxt" != x"$ntxt" ] ; then
    if [ -f $file ] ; then
      [ -f "$file$backupext" ] && $dryrun || rm -f "$file$backupext"
      [ -n "$backupext" ] && $dryrun || cp -dp "$file" "$file$backupext"
    fi
    if $encoded ; then
      $dryrun || (cat < "$tmpfile" >"$file")
    else
      $dryrun || (echo "$ntxt" | sed 's/^://' > "$file")
    fi
    msg=$(echo $msg updated)
  fi
  $encoded && [ -n "$tmpfile" ] && [ -f "$tmpfile" ] && rm -f "$tmpfile"

  if [ -n "$user" ] ; then
    if [ $(find "$file" -maxdepth 0 -user "$user" | wc -l) -eq 0 ] ; then
      $dryrun || chown "$user" "$file"
      msg=$(echo $msg chown)
    fi
  fi
  if [ -n "$group" ] ; then
    if [ $(find "$file" -maxdepth 0 -group "$group" | wc -l) -eq 0 ] ; then
      $dryrun || chgrp "$group" "$file"
      msg=$(echo $msg chgrp)
    fi
  fi
  if [ -n "$mode" ] ; then
    if [ $(find "$file" -maxdepth 0 -perm "$mode" | wc -l) -eq 0 ] ; then
      $dryrun || chmod "$mode" "$file"
      msg=$(echo $msg chmod)
    fi
  fi
  #$ :returns: 0 if file was changed, 1 if no change was needed, other non-zero values for error.
  #$ :output: File is updated if changed.  Filename and change summary is displayed on stderr.
  if [ -n "$msg" ] ; then
    echo "$file: $msg" 1>&2
    return 0
  fi
  return 1
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
  > no
  ( echo yes | xtf fixfile no ) || atf_fail "Failed compilation"
  rm -f no
}

xt_run() {
  : =descr "Run test"

  # 1. create file
  rm -f no
  ( echo yes | xtf fixfile no ) || atf_fail "File should have been created"
  [ -f no ] || atf_fail "File was not created"
  ( echo yes | xtf fixfile no ) && atf_fail "File should not have been changed"
  > no
  ( echo yes | xtf fixfile no ) || atf_fail "File should have been created"
  [ yes = $(cat no) ] || atf_fail "File contents did not match"

  ( echo 'tr a-z A-Z' | xtf fixfile --filter no ) || atf_fail "no capilals"
  [ YES = $(cat no) ] || atf_fail "File contents did not match"

  rm -f no no~
  ( echo yes | xtf fixfile no ) || atf_fail "File should have been created"
  [ -f no~ ] && atf_fail "Backup should not be created"
  ( echo no | xtf fixfile no ) || atf_fail "Changing file 199"
  [ -f no~ ] || atf_fail "Backup should have been created"
  ( echo yesno | xtf fixfile --backupext=.bak no ) || atf_fail "Changing file 201"
  [ -f no.bak ] || atf_fail "Backup should have been created"
  rm -f no~
  ( echo maybe | xtf fixfile --nobackup no ) || atf_fail "Changing file 204"
  [ -f no~ ] && atf_fail "Backup should not have been created"

  ( echo yes | gzip -v | base64 | xtf fixfile --decode no )  || atf_fail "Changing file 207"
  [ yes = $(cat no) ] || atf_fail "File contents did not match"

  chmod 600 no
  ( echo yesno | xtf fixfile --mode=666 no ) || atf_fail "Changing file 211"
  [ 666 -eq $(stat -c %a no) ] || atf_fail "chmod"

  rm -rf yes
  ( echo yes | xtf fixfile -D yes/no ) || atf_fail "File should have been created 214"
  [ -f yes/no ] || atf_fail "File was not created"

  # We are not testing user,group as this requires root access
  if type fakeroot ; then
    [ $(fakeroot sh -c "$(declare -f fixfile) ; echo yes | fixfile --user=1000 one ; stat -c %u one ") = 1000 ] || atf_fail "chuser"
    [ $(fakeroot sh -c "$(declare -f fixfile) ; echo yes | fixfile --group=1000 one ; stat -c %g one ") = 1000 ] || atf_fail "chgrpr"
  fi

  ( echo noyes | xtf fixfile --no-content no ) && atf_fail "Should not happen 224"

  rm -f no no~ no.bak one
  rm -rf yes
  :
}

xatf_init
