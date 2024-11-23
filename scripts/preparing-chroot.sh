#!/bin/bash


echo "LFS ${LFS:?}"
ls -la $LFS

#Changing Ownership
sudo chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
x86_64) sudo chown --from lfs -R root:root $LFS/lib64 ;;
esac

#Preparing Virtual Kernel File Systems
sudo mkdir -pv $LFS/{dev,proc,sys,run}
sudo mount -v --bind /dev $LFS/dev

sudo mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
    sudo install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
    sudo mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

sudo chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
