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
. $mydir/macro-virsh.sh
. $mydir/noxml.sh
. $mydir/ppxml.sh

ppxml <<'EOF'
# Comments	
domain type="kvm" "xmlns:qemu"="http://libvirt.org/schemas/domain/qemu/1.0":
  name: ts1
  uuid: $(m_uuid)
  memory unit="MiB": 1024
  vcpu: 1
  os:
    type arch="x86_64": hvm
    boot dev="cdrom"
    boot dev="hd"
  :
  features:
    acpi
  :
  clock sync="utc"
  devices:
    #~ emulator: /usr/bin/qemu-kvm
    watchdog model="i6300esb"
    console type="pty":
      target type="serial"
    :
    graphics type="vnc" port="-1":
      listen type="address" address="0.0.0.0"
    :
    # Storage configuration
    ##| m_disc_block vdev=vda path=/dev/hdvg0/ts1-v1
    ##| m_disc_file vdev=vdc file=/medias/isolib/boot-params/rs1.vfat
    ##| m_cdrom_local vdev="vdb" iso="/media/isolib/boot-cd/alpine-virt-3.7.0-x86_64.iso"
    ##| m_cdrom_http vdev="vdb" url="http://alvm1.localnet/Files/Temp/isolib-installers/os/elementary/elementaryos-0.3.2-stable-amd64.20151209.iso"
    # Network configuration
    ##| m_net_brnic br=br4

    # Create a private data channel.
    channel type="file":
      source path="/tmp/vm-serial.txt"
      target type="virtio" name="net.0ink.cmds.0"
    :
  :
  # Create a internal network that only allows traffic between guest and host
  "qemu:commandline":
    "qemu:arg" value="-netdev"
    "qemu:arg" value="user,id=int1,restrict,guestfwd=tcp:10.0.2.1:88-cmd:/usr/local/bin/xchan $domain_name,guestfwd=tcp:10.0.2.1:22-tcp:127.0.0.1:22"
    "qemu:arg" value="-device"
    "qemu:arg" value="virtio-net-pci,netdev=int1,id=ifnet1,mac=$(m_macaddr)"
  :
:
EOF

: xmlparse <<EOF
<domain type="kvm">
    <name>demo2</name>
    <uuid>4dea24b3-1d52-d8f3-2516-782e98a23fa0</uuid>
    <memory>131072</memory>
    <vcpu>1</vcpu>
    <os>
        <type arch="i686">hvm</type>
    </os>
    <clock sync="localtime"/>
    <devices>
        <emulator>/usr/bin/qemu-kvm</emulator>
        <disk type="file" device="disk">
            <source file="/var/lib/libvirt/images/demo2.img"/>
            <target dev="hda"/>
        </disk>
        <interface type="network">
            <source network="default"/>
            <mac address="24:42:53:21:52:45"/>
        </interface>
        <graphics type="vnc" port="-1"/>
    </devices>
</domain>
EOF



: <<EOF
# Comments
domain type="kvm":
  name: ts1
  uuid: $(m_uuid)
  memory unit="MiB": 1024
  vcpu: 1
  os:
    type arch="x86_64": hvm
    boot dev="network"
    boot dev="hd"
  :
  features:
    acpi
  :
  clock sync="utc"
  devices:
    #~ emulator: /usr/bin/qemu-kvm
    watchdog model="i6300esb"
    console type="pty":
      target type="serial"
    :
    graphics type="vnc" port="-1":
      listen type="address" address="0.0.0.0"
    :
    # Storage configuration
    disk type="block" device="disk":
      source dev="/dev/hdvg0/ts1-v1"
      target dev="vda"
    :
    # Network configuration
    #~ interface type="bridge":
      #~ source bridge="br0"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    #~ interface type="bridge":
      #~ source bridge="br1"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    #~ interface type="bridge":
      #~ source bridge="br2"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    #~ interface type="bridge":
      #~ source bridge="br3"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    interface type="bridge":
      source bridge="br4"
      mac address="$(m_macaddr)"
      model type="virtio"
    :
    #~ interface type="bridge":
      #~ source bridge="br5"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
EOF

: <<EOF
# Comments
domain type="kvm":
  name: rs1
  uuid: $(m_uuid)
  memory: 131072
  vcpu: 1
  os:
    type arch="x86_64": hvm
    boot dev="cdrom"
    boot dev="hd"
  :
  features:
    acpi
  :
  clock sync="utc"
  devices:
    #~ emulator: /usr/bin/qemu-kvm
    watchdog model="i6300esb"
    console type="pty":
      target type="serial"
    :
    graphics type="vnc" port="-1":
      listen type="address" address="0.0.0.0"
    :
    # Storage configuration
    disk type="block" device="disk":
      source dev="/dev/hdvg0/rs1-v1"
      target dev="vda"
    :
    #~ disk type="file" device="cdrom":
      #~ source file="/media/isolib/boot-cd/alpine-virt-3.7.0-x86_64.iso"
      #~ target dev="vdb"
    #~ :
    disk type="network" device="cdrom":
      source protocol="http" name="/alex/alpine-virt-3.7.0-x86_64.iso":
	host name="cvm1.localnet" port="80"
      :
      target dev="vdb"
    :
    disk type="file" device="disk":
      source file="/media/isolib/boot-parms/rs1.vfat"
      target dev="vdc"
    :

    # Network configuration
    #~ interface type="bridge":
      #~ source bridge="br0"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    interface type="bridge":
      source bridge="br1"
      mac address="$(m_macaddr)"
      model type="virtio"
    :
    #~ interface type="bridge":
      #~ source bridge="br2"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    #~ interface type="bridge":
      #~ source bridge="br3"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    #~ interface type="bridge":
      #~ source bridge="br4"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
    #~ interface type="bridge":
      #~ source bridge="br5"
      #~ mac address="$(m_macaddr)"
      #~ model type="virtio"
    #~ :
EOF


: <<EOF
# Comments
domain type="kvm":
  name: ts1
  uuid: $(m_uuid)
  memory unit="MiB": 1024
  vcpu: 1
  os:
    type arch="x86_64": hvm
    boot dev="cdrom"
    boot dev="hd"
  :
  features:
    acpi
  :
  clock sync="utc"
  devices:
    #~ emulator: /usr/bin/qemu-kvm
    watchdog model="i6300esb"
    console type="pty":
      target type="serial"
    :
    graphics type="vnc" port="-1":
      listen type="address" address="0.0.0.0"
    :
    # Storage configuration
    disk type="block" device="disk":
      source dev="/dev/hdvg0/ts1-v1"
      target dev="vda"
    :
    disk type="network" device="cdrom":
      source protocol="http" name="/Files/Temp/isolib-installers/os/elementary/elementaryos-0.3.2-stable-amd64.20151209.iso":
	host name="alvm1.localnet" port="80"
      :
      target dev="vdb"
    :
    # Network configuration
    interface type="bridge":
      source bridge="br4"
      mac address="$(m_macaddr)"
      model type="virtio"
    :
EOF
: <<EOF
# Comments
domain type="kvm":
  name: ts1
  uuid: $(m_uuid)
  memory unit="MiB": 1024
  vcpu: 1
  os:
    type arch="x86_64": hvm
    boot dev="cdrom"
    boot dev="hd"
  :
  features:
    acpi
  :
  clock sync="utc"
  devices:
    #~ emulator: /usr/bin/qemu-kvm
    watchdog model="i6300esb"
    console type="pty":
      target type="serial"
    :
    graphics type="vnc" port="-1":
      listen type="address" address="0.0.0.0"
    :
    # Storage configuration
    $(m_disc_block vdev=vda path=/dev/hdvg0/ts1-v1)
    $(m_disc_file vdev=vdc file=/medias/isolib/boot-params/rs1.vfat)
    $(m_cdrom_local vdev="vdb" iso="/media/isolib/boot-cd/alpine-virt-3.7.0-x86_64.iso")
    $(m_cdrom_http vdev="vdb" url="http://alvm1.localnet/Files/Temp/isolib-installers/os/elementary/elementaryos-0.3.2-stable-amd64.20151209.iso")
    # Network configuration
    $(m_net_brnic br=br4)
    channel type="file":
      source path="/tmp/vm-serial.txt"
      target type="virtio" name="net.0ink.cmds.0"
    :
  :
  "qemu:commandline":
    "qemu:arg" value="-netdev"
    "qemu:arg" value="user,id=int1,restrict,guestfwd=tcp:10.0.2.1:88-cmd:/bin/cat /etc/motd,guestfwd=tcp:10.0.2.1:22-tcp:127.0.0.1:22"
    "qemu:arg" value="-device"
    "qemu:arg" value="virtio-net-pci,netdev=int1,id=ifnet1,mac=$(m_macaddr)"
  :
  
EOF
