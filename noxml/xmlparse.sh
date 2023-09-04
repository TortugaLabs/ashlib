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
xmlparse() {
  local off="" prefix="${1:-CF}"
  local ln left right
  sed -e 's/^\s*//' -e 's/\s*$//' | (
    while read ln
    do
      ln=$(echo "$ln" | sed -e 's/^\s*//' -e 's/\s*$//')
      [ -z "$ln" ] && continue
      if ((echo $ln | grep -q '^<') && (echo $ln | grep -q '>$')) ; then
	ln=$(echo $ln | sed -e 's/^<\s*//' -e 's/\s*>$//')
	if (echo $ln | grep -q '>.*<') ; then
	  left=$(echo "$ln" | cut -d'>' -f1)
	  right=$(echo "$ln" | cut -d'>' -f2- | sed -e 's/<\s*\/[^>]*$//')
	  right=$(declare -p right | sed -e 's/^[^=]*//')
	  #right="='$right'"
	  for ln in $left
	  do
	    echo "${prefix}_${off}_$ln$right"
	    right=""
	  done
	elif (echo $ln | grep -q '/$') ; then
	  right="=1"
	  for left in $(echo $ln | sed 's/\/$//')
	  do
	    echo "${prefix}_${off}_$left$right"
	    right=""
	  done
	elif (echo $ln | grep -q '^/') ; then
	  off=$(
	    set - $(echo $off | tr '_' ' ')
	    o=""
	    while [ $# -gt 1 ]
	    do
	      if [ -z $o ] ; then
		o="$1"
	      else
		o="${o}_$1"
	      fi
	      shift
	    done
	    echo "$o"
	  )
	else
	  left="$(set - $ln ; echo "$1")"
	  echo "# $left ($off)"
	  if [ -z "$off" ] ; then
	    off="$left"
	  else
	    off="${off}_${left}"
	  fi
	  for right in $(set - $ln ; shift ; echo $*)
	  do
	    echo "${prefix}_${off}_${right}"
	  done
	fi
      else
	echo "Parser can not handle such complex XML!" 1>&2
	return 2
      fi
    done
  )
}


