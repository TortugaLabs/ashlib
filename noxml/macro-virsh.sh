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

m_error() {
  ## Handle error messages
  ## USAGE
  ##	m_error "message"
  ## DESC
  ## Will display a message on `stderr` prefixed with "ERROR:",
  ## and output the same message to stdout prefixed with "#".
  ##
  ## The rationale is that stdout is being saved to the output
  ## file, so we are marking the output with the error (as
  ## a comment).  While the console, will show the "ERROR" message
  ###
  echo "# $*"
  echo "ERROR: $*" 1>&2
  return 0
}

m_parse() {
  ## Parse command line arguments
  ## USAGE
  ##	local optname1="" optname2=""
  ##	local opts="optname1 optname2?"
  ##	m_parse cmd_name "$@" || return
  ## DESC
  ## Parse command-line switches for "key=value" pairs.
  ## "key" must have been defined in "$opts".  If "key" is not defined
  ## it is an error.
  ##
  ## If a key defined in "$opts" ends with "?", the key is treated
  ## as optional
  ##
  ## After all arguments are checked, it will make sure that all
  ## the $opts (which did not end with "?") have a value.
  local name="$1" ; shift
  local switch='case "$1" in'
  local i check=""
  for i in $opts
  do
    if (echo $i | grep -q '?$') ; then
      i=$(echo $i | sed -e 's/?$//')
    else
      if [ -z "$check" ] ; then
	check="$i"
      else
	check="$check $i"
      fi
    fi
    switch="$switch
	${i}=*) ${i}=\${1#$i=} ;; "
  done
  switch="$switch
	*) m_error \"$name: Invalid specification \\\"\$1\\\"\" ; return 1 ;;"
  switch="$switch
	esac"

  #echo "$switch"
  while [ $# -gt 0 ]
  do
    eval "$switch"
    shift
  done

  # Check if parameter is there...
  rc=0
  for i in $check
  do
    eval "local j=\${$i:-}"
    [ -n "$j" ] && continue
    rc=1
    m_error "$name: $i not specified"
  done

  return $rc
}


xmlns_qemu='"xmlns:qemu"="http://libvirt.org/schemas/domain/qemu/1.0"'

# Select from: http://standards-oui.ieee.org/oui/oui.txt
# Random OUI
oui_random="44:d2:ca"
oui_prefix="b8:78:79"
oui_changed="d8:60:b0"

random_hex() {
  echo $(od -An -N1 -t x1 /dev/urandom)
}

m_macaddr() {
  echo ${1:-$oui_random}:$(random_hex):$(random_hex):$(random_hex)
}

m_uuid() {
  ## Generate a random UUID
  ## USAGE
  ##	m_uuid
  if [ -f /proc/sys/kernel/random/uuid ] ; then
    cat /proc/sys/kernel/random/uuid
  else
    uuidgen
  fi
}

# Create a internal network that only allows traffic between guest and host
m_qemu_adm_interface() {
  local id="int1" type="virtio-net-pci" mac="" xchan="/usr/local/bin/xchan"
  local opts="id type mac? xchan"
  m_parse m_qemu_adm_interface "$@" || return 1
  [ -z "$mac" ] && mac=$(m_macaddr)
  [ $(expr length "$mac") -eq 8 ] && mac="$oui_prefix:$mac"
  (
    cat <<-EOF
	"qemu:commandline":
	  "qemu:arg" value="-netdev"
	  "qemu:arg" value="user,id=$id,restrict,guestfwd=tcp:10.0.2.1:88-cmd:$xchan $domain_name,guestfwd=tcp:10.0.2.1:22-tcp:127.0.0.1:22"
	  "qemu:arg" value="-device"
	  "qemu:arg" value="$type,netdev=$id,id=ifnet$id,mac=$mac"
	:
	EOF
  ) | xmlgen "$off" | ns_hack
}

m_disc_block() {
  local vdev="" path=""
  local opts="vdev path"
  m_parse m_disc_block "$@" || return 1
  cat <<-_EOF_
    disk type="block" device="disk":
      source dev="$path"
      target dev="$vdev"
    :
	_EOF_
}
m_disc_file() {
  local vdev="" file=""
  local opts="vdev file"
  m_parse m_disc_file "$@" || return 1
  cat <<-_EOF_
    disk type="file" device="disk":
      source file="$file"
      target dev="$vdev"
    :
	_EOF_
}

m_cdrom_local() {
  local vdev="" iso=""
  local opts="vdev iso"
  m_parse m_cdrom_local "$@" || return 1
  cat <<-_EOF_
    disk type="file" device="cdrom":
      source file="$iso"
      target dev="$vdev"
    :
	_EOF_
}
m_cdrom_http() {
  local vdev="" url=""
  local opts="vdev url"
  m_parse m_cdrom_http "$@" || return 1

  local proto=$(echo "$url" | cut -d: -f1)
  local path=$(echo "$url" | cut -d: -f2- | sed -e 's!^//!!')
  local host=$(echo "$path" | cut -d/ -f1) port=80
  path=/$(echo "$path" | cut -d/ -f2-)
  if (echo $host | grep -q :) ; then
    port=$(echo $host | cut -d: -f2-)
    host=$(echo $host | cut -d: -f1)
  fi
  cat <<-_EOF_
    disk type="network" device="cdrom":
      source protocol="$proto" name="$path":
	host name="$host" port="$port"
      :
      target dev="$vdev"
    :
	_EOF_
}

m_net_brnic() {
  local br=br0 mac="" type="virtio"
  local opts="br mac? type"
  m_parse m_net_brnic "$@" || return 1
  [ -z "$mac" ] && mac=$(m_macaddr)
  [ $(expr length "$mac") -eq 8 ] && mac="$oui_prefix:$mac"

  cat <<-_EOF_
    interface type="bridge":
      source bridge="$br"
      mac address="$mac"
      model type="$type"
    :
	_EOF_
}



