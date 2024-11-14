# vJunos_on_Proxmox
vJunos(switch, router & vEVO) deployment on Proxmox 8.2.x

### vJunos Overview

vJunos is a virtual version of a Juniper switch/router/EVO based switch that runs the Junos OS. vJunos has majorly 3 flavors: vJunos-switch, vJunos-router & vJunosEvolved.

You can install a vJunos-switch or vJunos-router or vJunosEvolved as a virtual machine (VM) on an x86 server.

The vJunos-switch is built using EX9214 as a reference Juniper switch and supports a single Routing Engine and single Flexible PIC Concentrator (FPC).
The vJunos-router is built using vMX as a reference Juniper router and supports a single Routing Engine and single Flexible PIC Concentrator (FPC).
The vJunosEvolved is built using PTX10001-36MR as a reference Juniper switch, which is a fixed-configuration packet transport router on the Junos® OS Evolved platform.

The vJunos node is a single virtual machine (VM) that is targeted for lab environment only and not for production environment. 
The vJunos nodes supports a bandwidth of up to 100 Mbps aggregated over all the interfaces. You can configure and manage the vJunos nodes in the same way as you manage a physical node.

This article explains the vJunos installation on a Proxmox server as VM.


### Create the base vJunos VMs

Copy vJunos images(qcow2) file to Proxmox server
-	Create a new folder ‘/root/import/vjunos/’
-	Copy vJunos qcow2 files to new folder(‘/root/import/vjunos/’) on Proxmox host.

Create a new VM with below minimum settings:
-	Cpu: 4 cores <vmid>
-	Memory: 5Gb(for vjunos-switch/router), 8Gb(for vJunosEvolved)
-	No hard drive
-	No install media
-	Single virtio NIC on vmbr0 bridge for the management interface (fxp0)
-	Add serial port for terminal access. Command to access the vJunos console:
	```
	qm terminal <vmid>
	```

Import vjunos image(.qcow2) as a virtio0 drive attached to the new vJunos VM via CLI:
-	Import corresponding vJunos Image to the base vJunos VM
	```
	qm importdisk <vmid> <imagefilename.qcow2> <storage-pool> -format qcow2
	```
-	The disk should show up in the UI as ‘Unused Disk 0’ in the Hardware section of the VM.
-	Click the disk, then ‘Edit’. Change to ‘VirtIO/Block’ and then click ‘Add’.
-	Go to Options and change the boot order so the new disk is the first boot option.

Set the qemu args properly as below, once the VMs are created from UI:
-	get the VM id for the vJuons VM and edit respective VM config file located at: ‘/etc/pve/qemu-server/\<vmid\>.conf’
- 	add the specific qemu args at ‘/etc/pve/qemu-server/\<vmid\>.conf’ as below:
	-	for vjunos-switch add below line at the staring of the file:   
	```	
	args: -machine accel=kvm:tcg -smbios type=1,product=VM-VEX -cpu 'host,kvm=on'
	```
	-	for vjunos-router add below line at the staring of the file:
	```
	args: -machine accel=kvm:tcg -smbios type=1,product=VM-VMX,family=lab -cpu 'host,kvm=on'
	```
	-	for vjunos-evolved add below line at the staring of the file:
	```
	args: -machine accel=kvm:tcg -smbios 'type=0,vendor=Bochs,version=Bochs'  -smbios 'type=3,manufacturer=Bochs' -smbios 'type=1,manufacturer=Bochs,product=Bochs,serial=chassis_no=0:slot=0:type=1:assembly_id=0x0d20:platform=251:master=0: channelized=yes' -cpu host
	```	

Power on VM and ensure that the vJunos VM boots. From here you can assign an IP address to fxp0 or you can shut the VM down and make it into a template for cloning to new vjunos nodes.
-	Commands to power on vJunos VM and login to console from CLI at Proxmox Host:
	```
	qm start <vmid> && qm terminal <vmid>
	```

Note: All vJunos needs to shutdown gracefully to maintain the last committed config for next boot. Use the below junos CLI command to power down the vJunos gracefully:
```
vjunos1> request system power-off at now
```
Shutdown from junos shell or power off the VM can corrupt the VM disk or the latest committed config. Therefore, to keep the last committed config always gracefully shutdown the vJunos VM.

Alternately, you can use below 2 scripts to automate the VM boot(for vJunos-switch or vJunos-router) 
- "rebuild-vjunos.sh" : boot vJunos VM with pre-loaded base config at first boot
- "rebuild-vjunos-shutdown.sh" : download the latest config from live vJunos node and prepare the VM Disks for next boot with latest config.      



### Boot vJunos VM with pre-loaded base configs 

- copy the disk folder under /root/
- Edit the below .sh scripts & provide the vjunos Image location & proxmox LVM/Disk storage name
	```
  	nano /root/disk/vjunos-switch/rebuild-vjunos.sh
  	nano /root/disk/vjunos-router/rebuild-vjunos.sh
	```
- next make sure the vJunos VM is powered off
- next for vjunos-switch go to /root/disk/vjunos-switch/ and execute the below command:
	```
 	root@Proxmox:~# cd /root/disk/vjunos-switch/
 	root@Proxmox:~/disk/vjunos-switch# sh rebuild-vjunos.sh vjunos.conf 6201
 	root@Proxmox:~/disk/vjunos-switch# ./rebuild-vjunos.sh -help
 	Usage :  sh rebuild-vjunos.sh <juniper-config> <vjunos-vm-id>	
	```
- next for vjunos-router go to /root/disk/vjunos-router/ and execute the below command:
	```
 	root@Proxmox:~# cd /root/disk/vjunos-router/
 	root@Proxmox:~/disk/vjunos-router# sh rebuild-vjunos.sh vjunos.conf 6202
 	root@Proxmox:~/disk/vjunos-router# ./rebuild-vjunos.sh -help
 	Usage :  sh rebuild-vjunos.sh <juniper-config> <vjunos-vm-id>
	```
- next normally boot the vjunos node and login via console or ssh to fxp0 IP.



### Shutdown script to prepare VM Disks with latest config for next boot

- copy the disk folder under /root/
- Edit the below .sh scripts & provide the vjunos Image location & proxmox LVM/Disk storage name
	```
	nano /root/disk/vjunos-switch/rebuild-vjunos-shutdown.sh
	nano /root/disk/vjunos-router/rebuild-vjunos-shutdown.sh
	```
- next make sure the vJunos VM is powered on with fxp0 IP and reachability.
- next for vjunos-switch go to /root/disk/vjunos-switch/ and execute the below command:
	```
 	root@Proxmox:~# cd /root/disk/vjunos-switch/
	root@Proxmox:~/disk/vjunos-switch# sh rebuild-vjunos-shutdown.sh 192.168.0.251 6201
 	root@Proxmox:~/disk/vjunos-switch# ./rebuild-vjunos-shutdown.sh -help
 	Usage :  sh rebuild-vjunos-shutdown.sh <vjunos-fxp0-IP> <vjunos-vm-id>
	```
  during the execution provide the vjunos login credentials to fetch the latest committed config from vjunos node.

- next for vjunos-router go to /root/disk/vjunos-router/ and execute the below command:
	```
	root@Proxmox:~# cd /root/disk/vjunos-router/
	root@Proxmox:~/disk/vjunos-router# sh rebuild-vjunos-shutdown.sh 192.168.0.250 6202
 	root@Proxmox:~/disk/vjunos-router# ./rebuild-vjunos-shutdown.sh -help
 	Usage :  sh rebuild-vjunos-shutdown.sh <vjunos-fxp0-IP> <vjunos-vm-id>
	```
  during the execution provide the vjunos login credentials to fetch the latest committed config from vjunos node.

- next normally boot the vjunos node and login via console or ssh to fxp0 IP.

### Activate LLDP & LACP over the VMX interfaces/linux bridge

- First disable the firewall from each side of the LLDP or LACP tap interfaces
  	GUI: from Server view : Proxmox-server -> VMID -> Hardware -> Network Device (netX) <edit> -> Untick "Firewall:" box
  	CLI: Modify /etc/pve/qemu-server/VMID.conf as below, then same the file and start the VM.
  	```
	root@Proxmox-Dell7070:~# nano /etc/pve/qemu-server/6008.conf 
	. . .
	net4: virtio=BC:24:11:24:E8:09,bridge=vmbr501,firewall=1
	net5: virtio=BC:24:11:62:74:EE,bridge=vmbr502,firewall=1
   	. . .
   	<modify to>
   	. . .
	net4: virtio=BC:24:11:24:E8:09,bridge=vmbr501
	net5: virtio=BC:24:11:62:74:EE,bridge=vmbr502
   	. . .
   	``` 
- Next get the bridge name & tap interfaces detals with brctl commands:
	```
	root@Proxmox-Dell7070:~# brctl show
	bridge name     bridge id               STP enabled     interfaces
	. . . .
	vmbr501         8000.ca88e9bc7566       no              tap6008i4
	                                                        tap6014i3
	vmbr502         8000.02ac38a16614       no              tap6008i5
	                                                        tap6014i4
	vmbr503         8000.c6382edfc5e2       no              tap6012i4
	                                                        tap6014i5
	vmbr504         8000.ee7205b4afcc       no              tap6012i5
	                                                        tap6014i6
	vmbr505         8000.e20e7fe564e0       no              fwpr6013p2
	                                                        tap6002i8
	                                                        tap6002i9
	                                                        tap6004i8
	                                                        tap6004i9
 	. . . .
 	```
- For LLDP only the bridges need to be modified as following:
	```
	echo '0x4000' > /sys/class/net/BRIDGE-NAME/bridge/group_fwd_mask
	```

- For LACP, the specific tap interfaces on both sides of lacp link need to be modified as following :
	```
	echo 16388 > /sys/class/net/VM1-TAP-INTERFACE/brport/group_fwd_mask
	echo 16388 > /sys/class/net/VM2-TAP-INTERFACE/brport/group_fwd_mask
	or 
	echo '0x4004' > /sys/class/net/VM1-TAP-INTERFACE/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/VM2-TAP-INTERFACE/brport/group_fwd_mask
	```
 	#### Example:
	```
	echo '0x4004' > /sys/class/net/tap6008i4/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/tap6014i3/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/tap6008i5/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/tap6014i4/brport/group_fwd_mask

	echo '0x4004' > /sys/class/net/tap6012i4/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/tap6014i5/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/tap6012i5/brport/group_fwd_mask
	echo '0x4004' > /sys/class/net/tap6014i6/brport/group_fwd_mask
	```


