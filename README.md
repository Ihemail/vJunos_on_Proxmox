# vJunos_on_Proxmox
vJunos(switch, router & vEVO) deployment on Proxmox 8.2.x

### vJunos Overview

vJunos is a virtual version of a Juniper switch/router/EVO based switch that runs the Junos OS. vJunos has majorly 3 flavors: vJunos-switch, vJunos-router & vJunosEvolved 
You can install a vJunos-switch or vJunos-router or vJunosEvolved as a virtual machine (VM) on an x86 server.

The vJunos-switch is built using EX9214 as a reference Juniper switch and supports a single Routing Engine and single Flexible PIC Concentrator (FPC).
The vJunos-router is built using vMX as a reference Juniper router and supports a single Routing Engine and single Flexible PIC Concentrator (FPC).
The vJunosEvolved is built using PTX10001-36MR as a reference Juniper switch, which is a fixed-configuration packet transport router on the Junos® OS Evolved platform.

The vJunos node is a single virtual machine (VM) that is targeted for lab environment only and not for production environment. 
The vJunos nodes supports a bandwidth of up to 100 Mbps aggregated over all the interfaces. You can configure and manage the vJunos nodes in the same way as you manage a physical node.

This article explains the vJunos installation on a Proxmox server as VM:

### Create the base vJunos VMs

Copy vJunos images(qcow2) file to Proxmox server
-	Create a new folder ‘/root/import/vjunos/’
-	Copy vJunos qcow2 files to new folder(‘/root/import/vjunos/’) on Proxmox host.

Create a new VM with below minimum settings:
-	cpu: 4 cores 
-	memory: 5Gb(for vjunos-switch/router), 8Gb(for vJunosEvolved)
-	No hard drive
-	No install media
-	Single virtio NIC on vmbr0 bridge for the management interface (fxp0)
-	Add serial port for terminal access.
	cmd to access the console: ‘qm terminal <VMID>’

Import qcow2 file as a drive attached to the new VM via CLI:
-	‘qm importdisk <VMID> <imagefilename.qcow2> <storage-pool> -format qcow2’
-	The disk should show up in the UI as ‘Unused Disk 0’ in the Hardware section of the VM.
-	Click the disk, then ‘Edit’. Change to ‘VirtIO/Block’ and then click ‘Add’.
-	Go to Options and change the boot order so the new disk is the first boot option.

Set the qemu args properly as below once the VMs are created from UI:
-	get the VM id for the vJuons VM and edit respective VM config file located at: ‘/etc/pve/qemu-server/<VMID>.conf’
-   add the specific qemu args at ‘/etc/pve/qemu-server/<VMID>.conf’ as below:

	for vjunos-switch add below line at the staring of the file:
```	
	"args: -machine accel=kvm:tcg -smbios type=1,product=VM-VEX -cpu 'host,kvm=on'"
```

	for vjunos-router add below line at the staring of the file:
```
	"args: -machine accel=kvm:tcg -smbios type=1,product=VM-VMX,family=lab -cpu 'host,kvm=on'"
```

	for vjunos-evolved add below line at the staring of the file:
```
	"args: -machine accel=kvm:tcg -smbios 'type=0,vendor=Bochs,version=Bochs'  -smbios 'type=3,manufacturer=Bochs' -smbios 'type=1,manufacturer=Bochs,product=Bochs,serial=chassis_no=0:slot=0:type=1:assembly_id=0x0d20:platform=251:master=0: channelized=yes' -cpu host"
```
	
Power on VM and ensure that it boots. From here you can assign an IP address to fxp0 or you can shut the VM down and make it into a template for cloning to new vjunos nodes.

Please not: All vJunos need to shutdown gracefully from the junos CLI only using below command:
- ‘request system power-off at now’ to maintain the last config at need boot. Shutdown from shell or power off the VM can corrupt the VM Disk or laest config files.

Therefore, to keep the last comitted config for next boot always gracefully shutdown the vJunos VM

Alternately, you can use below 2 scripts to automate the VM boot(for vJunos-switch or vJunos-router) 
- "rebuild-vjunos.sh" : boot vJunos VM with pre-loaded base configs at first boot
- "rebuild-vjunos-shutdown.sh" : download the latest config from live vJunos node and prepare the VM Disks for next boot with latest config.      


### Boot vJunos VM with pre-loaded base configs 
- copy the disk folder under /root/
- Edit the below .sh scripts & provide the vjunos Image & proxmox LVM/DISK storage name
  nano /root/disk/vjunos-switch/rebuild-vjunos.sh
  nano /root/disk/vjunos-router/rebuild-vjunos.sh  
- next make sure the vJunos VM is powered off
- next for vjunos-switch go to /root/disk/vjunos-router and execute the below command:
```
  Usage :  rebuild-vjunos.sh <juniper-config> <vjunos-vm-id>
  example:  sh rebuild-vjunos.sh vjunos.conf 6201
```
- next for vjunos-router go to /root/disk/vjunos-router and execute the below command:
```
  Usage : rebuild-vjunos.sh <juniper-config> <vjunos-vm-id>
  example: sh rebuild-vjunos.sh vjunos.conf 6202
```
- next normally boot the vjunos node and 

### Shutdown script to prepare VM Disks with latest config for nxct boot
- copy the disk folder under /root/
- Edit the below .sh scripts & provide the vjunos Image & proxmox LVM/DISK storage name
```
  nano /root/disk/vjunos-switch/rebuild-vjunos-shutdown.sh
  nano /root/disk/vjunos-router/rebuild-vjunos-shutdown.sh
```
- next make sure the vJunos VM is powered on with fxp0 IP and reachability.
- next for vjunos-switch go to /root/disk/vjunos-router and execute the below command:
```
  Usage : rebuild-vjunos-shutdown.sh <vjunos-fxp0-IP> <vjunos-vm-id>
  example: sh rebuild-vjunos-shutdown.sh 192.168.0.251 6201
```
  during the execution provide the vjunos login credentials to get the latest committed config from vjunos node.

- next for vjunos-router go to /root/disk/vjunos-router and execute the below command:
```
  Usage : rebuild-vjunos-shutdown.sh <vjunos-fxp0-IP> <vjunos-vm-id>
  example: sh rebuild-vjunos-shutdown.sh 192.168.0.250 6202
```
  during the execution provide the vjunos login credentials to get the latest committed config from vjunos node.

