#!/bin/bash
#
# make-config.sh
#
# Copyright (c) 2023, Juniper Networks, Inc.
# All rights reserved.
#
# Rebuild vJunos with config metadisk from a supplied juniper.conf to attach to a vJunos VM instance
# During execution put ssh login credentials to copy ssh-key: ssh-copy-id root@<vjunos-fxp0-IP> 
#

usage() {
	echo "Usage : rebuild-vjunos-shutdown.sh <vjunos-fxp0-IP> <vjunos-vm-id>"
	exit 0;
}

if [ $# != 2 ]; then
	usage;
fi

# Provide vJunos router Image location here for vJunos image rebuild
VJUNOSIMG="/root/import/vJunos/vJunos-switch-23.2R1.14.qcow2"

# Provide Proxmox LVM disk name here
PROXMOXLVM="hdd-lvm"

ssh-copy-id root@$1
sleep 10

scp root@$1:/config/juniper.conf.gz sftp/juniper.conf.gz.$2
cp sftp/juniper.conf.gz.$2 juniper.conf.gz
sh make-conf-v23.2.sh juniper.conf.gz config-disk.img

 qm stop $2
 sleep 3
 qm set $2 --delete ide0
 qm set $2 --delete virtio0
 qm set $2 --delete unused0
 qm set $2 --delete unused1

 qm importdisk $2 $VJUNOSIMG $PROXMOXLVM -format qcow2
 qm importdisk $2 config-disk.img $PROXMOXLVM -format raw

sed -i "s/unused0: $PROXMOXLVM:vm-$2-disk-0/virtio0: $PROXMOXLVM:vm-$2-disk-0,iothread=1,size=32524M/g" /etc/pve/qemu-server/$2.conf
sed -i "s/unused1: $PROXMOXLVM:vm-$2-disk-1/ide0: $PROXMOXLVM:vm-$2-disk-1,size=16M/g" /etc/pve/qemu-server/$2.conf
sed -i "s/boot: /boot: order=virtio0/g" /etc/pve/qemu-server/$2.conf

rm -rf juniper.conf.gz
rm -rf config-disk.img

echo "vJunos config backup and rebuild for vjunos ID $2 complete."
exit 0

