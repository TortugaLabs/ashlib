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

mydir=$(dirname "$(readlink -f "$0")")
export LIBDIR="$(dirname "$mydir")/lib"
export PATH=$PATH:$mydir:$LIBDIR

. noxml.sh
. ppxml.sh

if [ $# -eq 0 ] ; then
  echo "Usage: $0 {input.cfm} ..."
  exit 1
fi

rc=0
done='[OK]'
for input in "$@"
do
  if [ x"$input" = x"-" ] ; then
    set -
    ppxml || rc=1
  else
    if [ ! -f "$input" ] ; then
      echo "$input: not found" 1>&2
      continue
    fi
    output=$(echo $input | sed -e 's/\.cfm$/.xml/')
    name=$(basename "$output" .xml)
    if [ x"$input" = x"$output" ] ; then
      output="$input.xml"
    fi
    [ $# -gt 1 ] && echo -n "$input " 1>&2
    if ! ppxml <"$input" >"$output" ; then
      rc=1
      done='[ERROR]'
    fi
  fi
done

[ $# -gt 1 ] && echo "$done" 1>&2
exit $rc

