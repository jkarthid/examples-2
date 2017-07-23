# Override system parameters
To override kernel parameters in /etc/system or set custom config for specific modules you can:
* recreate boot_archive
* use overridefs module

## Mount usb flash and configure grub
```
[root@smartos ~]# mount -F pcfs /dev/dsk/c0t0d0p1 /mnt
[root@smartos ~]# cd /mnt/boot/grub/
[root@smartos /mnt/boot/grub]# cat menu.lst
default=0
timeout=10
min_mem64 1024
serial --speed=115200 --unit=1,0,2,3 --word=8 --parity=no --stop=1
terminal composite
variable os_console vga

title SmartOS
   kernel$ /platform/i86pc/kernel/amd64/unix -B console=${os_console},${os_console}-mode="115200,8,n,1,-",root_shadow='$5$2HOHRnK3$NvLlm.1KQBbB0WjoP7xcIwGnllhzp2HnT.mDO7DpxYA',smartos=true
   module /platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk
   module /platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk
   module /override/etc/system type=file name=etc/system


title SmartOS noinstall/recovery (login/pw: root/root)
   kernel$ /platform/i86pc/kernel/amd64/unix -B console=${os_console},${os_console}-mode="115200,8,n,1,-",root_shadow='$5$2HOHRnK3$NvLlm.1KQBbB0WjoP7xcIwGnllhzp2HnT.mDO7DpxYA',standalone=true,noimport=true
   module /platform/i86pc/amd64/boot_archive

title SmartOS +kmdb
   kernel$ /platform/i86pc/kernel/amd64/unix -kd -B console=${os_console},${os_console}-mode="115200,8,n,1,-",root_shadow='$5$2HOHRnK3$NvLlm.1KQBbB0WjoP7xcIwGnllhzp2HnT.mDO7DpxYA',smartos=true
   module /platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk
   module /platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk
   module /override/etc/system type=file name=etc/system
[root@smartos /mnt/boot/grub]# vim menu.lst
[root@smartos /mnt/boot/grub]# cat menu.lst
default=0
timeout=10
min_mem64 1024
serial --speed=115200 --unit=1,0,2,3 --word=8 --parity=no --stop=1
terminal composite
variable os_console vga

title SmartOS
   kernel$ /platform/i86pc/kernel/amd64/unix -B console=${os_console},${os_console}-mode="115200,8,n,1,-",root_shadow='$5$2HOHRnK3$NvLlm.1KQBbB0WjoP7xcIwGnllhzp2HnT.mDO7DpxYA',smartos=true
   module /platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk
   module /platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk
   module /override/etc/system type=file name=etc/system


title SmartOS noinstall/recovery (login/pw: root/root)
   kernel$ /platform/i86pc/kernel/amd64/unix -B console=${os_console},${os_console}-mode="115200,8,n,1,-",root_shadow='$5$2HOHRnK3$NvLlm.1KQBbB0WjoP7xcIwGnllhzp2HnT.mDO7DpxYA',standalone=true,noimport=true
   module /platform/i86pc/amd64/boot_archive

title SmartOS +kmdb
   kernel$ /platform/i86pc/kernel/amd64/unix -kd -B console=${os_console},${os_console}-mode="115200,8,n,1,-",root_shadow='$5$2HOHRnK3$NvLlm.1KQBbB0WjoP7xcIwGnllhzp2HnT.mDO7DpxYA',smartos=true
   module /platform/i86pc/amd64/boot_archive
```

## Override configs
```
[root@smartos /mnt/boot/grub]# egrep "^set" /mnt/override/etc/system  
set ibft_noprobe=1
set noexec_user_stack=1
set noexec_user_stack_log=1
set rlim_fd_cur=65536
set idle_cpu_no_deep_c=1
set ip:ip_squeue_fanout=1
set pcplusmp:apic_panic_on_nmi=1
set apix:apic_panic_on_nmi=1
set dump_plat_mincpu=0
set dump_bzip2_level=1
set pcplusmp:apic_timer_preferred_mode=0
set apix:apic_timer_preferred_mode=0
set dump_metrics_on=1
set sata:sata_auto_online=1
set sd:sd_io_time=10
set hires_tick=1
set zfs:zfs_txg_timeout = 0xa
```

## Notice
When you reboot your system, file /etc/system will be mounted from boot archive, and not contain our changes, but it will be applied to system, you can check it through mdb
