#!/usr/bin/atf-sh

#|****f* ashlib/fixattr
#| NAME
#|   fixattr -- update file attributes
fixattr() {
  #| USAGE
  #|   fixattr [options] file
  local mode="" user="" group=""
  #| ARGUMENTS
  #|   * --mode=mode -- Target file mode
  #|   * --user=user -- User to own the file
  #|   * --group=group -- Group that owns the file
  #|   * file -- file to modify.
  while [ $# -gt 0 ]
  do
    case "$1" in
      --mode=*) mode=${1#--mode=} ;;
      --user=*) user=${1#--user=} ;;
      --group=*) group=${1#--group=} ;;
      --) shift ; break ;;
      -*) echo "Invalid option: $1" 1>&2 ; return 1 ;;
	;;
      *) break ;;
    esac
    shift
  done

  #| DESCRIPTION
  #|   This function ensures that the given `file` has the defined file modes,
  #|   owner user and owner groups.
  #|
  #|   This snippet is provided for scripts that are not using the fixfile
  #|   snippet.  The fixfile snippet has a --no-content option that works
  #|   like fixattr.  You can then do:
  #|      fixattr() { fixfile --no-content "$@"; }
  #|   to provide fixattr functionality using fixfile.

  if [ $# -eq 0 ] ; then
    echo "No file specified" 1>&2
    return 1
  fi
  local file="$1" ; shift
  [ $# -gt 1 ] && echo "Ignoring additional options: $*" 1>&2

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

  local msg=""

  if [ -n "$user" ] ; then
    if [ $(find "$file" -maxdepth 0 -user "$user" | wc -l) -eq 0 ] ; then
      chown "$user" "$file"
      msg=$(echo $msg chown)
    fi
  fi
  if [ -n "$group" ] ; then
    if [ $(find "$file" -maxdepth 0 -group "$group" | wc -l) -eq 0 ] ; then
      chgrp "$group" "$file"
      msg=$(echo $msg chgrp)
    fi
  fi
  if [ -n "$mode" ] ; then
    if [ $(find "$file" -maxdepth 0 -perm "$mode" | wc -l) -eq 0 ] ; then
      chmod "$mode" "$file"
      msg=$(echo $msg chmod)
    fi
  fi
  #| RETURN VALUE
  #|   Returns true if file was changed, false if no change was needed
  #|****
  if [ -n "$MSG" ] ; then
    echo "$file: $msg" 1>&2
    return 0
  fi
  return 1

}

