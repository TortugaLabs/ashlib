#!/bin/sh
#
# Copyright (c) 2018 Alejandro Liu
# Licensed under the MIT license:
#
# Permission is  hereby granted,  free of charge,  to any  person obtaining
# a  copy  of  this  software   and  associated  documentation  files  (the
# "Software"),  to  deal in  the  Software  without restriction,  including
# without  limitation the  rights  to use,  copy,  modify, merge,  publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons  to whom  the Software  is  furnished to  do so,  subject to  the
# following conditions:
#
# The above copyright  notice and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE  SOFTWARE  IS  PROVIDED  "AS  IS",  WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS  OR IMPLIED,  INCLUDING  BUT  NOT LIMITED  TO  THE WARRANTIES  OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR  OTHER LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT,  TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
set -euf -o pipefail


_pp_expand() {
  local eof="EOF_$$_EOF_$$_EOF"
  eval "
cat <<$eof
$*
$eof" | ns_hack
}


ppxml() {
  local loose=false
  [ $# -gt 0 ] && [ x"$1" = x"--loose" ] && loose=true
  
  local \
	off="" \
	pops="" \
	ln="" left="" right="" tag="" k=0
  local v_prefix='' v_stack=""

  while read ln
  do
    k=$(expr $k + 1)
    if ( echo "$ln" | grep -qE '^\s*##!' ) ; then
      eval "$(echo "$ln" | sed -e 's/^\s*##!\s*//')"
      continue
    elif ( echo "$ln" | grep -qE '^\s*##\|' ) ; then
      eval "$(echo "$ln" | sed -e 's/^\s*##|\s*//')" | xmlgen "$off"
      continue
    fi
    ln="$(echo "$ln" | sed -e 's/^\s*#.*$//' -e 's/^\s*//' -e 's/\s*$//')"
    [ -z "$ln" ] && continue
    
    if [ x"$ln" = x":" -o x"$ln" = x"/" ] ; then
      _pop_tag
      _pp_expand "$off</$tag>"
      if [ -n "$v_stack" ] ; then
	v_prefix=$(set - $v_stack ; echo "$1")
	v_stack=$(set - $v_stack ; shift ; echo "$*")
      fi
    elif _split_cfg_line "$ln" left right ; then
      # Found
      tag=$(echo "$left" | (read a b ; echo $a))
      local tag_var="$v_prefix$(echo $tag | tr -dc _A-Za-z0-9)"
      if [ -z "$right" ] ; then
	# Open tag...
	_pp_expand "$off<$left>"
	pops=$(echo $tag $pops)
	off="  $off"
	if [ -n "$v_prefix" ] ; then
	  if [ -z "$v_stack" ] ; then
	    v_stack="$v_prefix"
	  else
	    v_stack="$v_prefix $v_stack"
	  fi
	fi
	v_prefix="${tag_var}_"
      else
	# Single line content
	_pp_expand "$off<$left>$right</$tag>"
	eval "${tag_var}=\"$right\""
      fi
    else
      # Self contained tag
      _pp_expand "$off<$ln />"
    fi
  done
  if ! $loose ; then
    [ -n "$pops" ] && echo "Un-closed tags: $pops" 1>&2
  fi
  while [ -n "$pops" ]
  do
    _pop_tag
    _pp_expand "$off</$tag>"
  done
}

