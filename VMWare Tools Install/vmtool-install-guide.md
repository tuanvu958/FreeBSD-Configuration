Require
	※　Install /usr/ports/misc/compat6x
	※　Link perl to: /usr/bin/perl

1, On Vmware, mount vmware-freebsd-tool iso file to CD-ROM
2, On FreeBSD Guest OS, mount iso to system
	# mount -t cd9660 /dev/iso9660 /cdrom
3, Copy installer file to tmp folder
4, Unrar installer file
5, Install vmware-freebsd-tool
	# cd vmware-tools-distrib/
	# ./vmware-install.pl (perl is necessary)


＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

On FreeBSD11

# and install Open VM Tools by FreeBSD package manager
# pkg install open-vm-tools-nox11　(X11)
pkg install open-vm-tools  (using)

To run the Open Virtual Machine tools at startup, you must add the following settings to your /etc/rc.conf

vmware_guest_vmblock_enable="YES"
vmware_guest_vmhgfs_enable="NO"
vmware_guest_vmmemctl_enable="YES"
vmware_guest_vmxnet_enable="YES"
vmware_guestd_enable="YES"
