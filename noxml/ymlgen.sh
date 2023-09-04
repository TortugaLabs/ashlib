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

ymlgen() {
  local off=""
  local ln left right
  sed -e 's/^\s*//' -e 's/\s*$//' | (
    while read ln
    do
      [ -z "$ln" ] && continue
      if ((echo $ln | grep -q '^<') && (echo $ln | grep -q '>$')) ; then
	ln=$(echo $ln | sed -e 's/^<\s*//' -e 's/\s*>$//')
	if (echo $ln | grep -q '>.*<') ; then
	  left=$(echo "$ln" | cut -d'>' -f1)
	  right=$(echo "$ln" | cut -d'>' -f2- | sed -e 's/<\s*\/[^>]*$//')
	  echo "$off$left: $right"
	elif (echo $ln | grep -q '/$') ; then
	  echo "$off$(echo "$ln" | sed -e 's!\s*/$!!')"
	elif (echo $ln | grep -q '^/') ; then
	  off="$(expr substr "$off" 1 $(expr $(expr length "$off") - 2))"
	  echo "$off:"
	else
	  echo "$off$ln:"
	  off="$off  "
	fi
      else
	echo "Parser can not handle such complex XML!" 1>&2
	return 2
      fi
    done
  )
}
