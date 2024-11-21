#!/bin/bash

prepareDir() {
    echo "------------ Preparing Dir -----------"
    echo "Preparing $PWD/$1"
    dir=$(tar -tf "$1" | head -1 | cut -f1 -d"/")
    echo "cd Into Directory: $dir"
    tar -xvf $1
    pushd "$PWD/source/$dir"
    $2
    popd
    rm -rf "$PWD/source/$dir"
    echo "------------ *************** -----------"
}

#Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

#Essential Files and Symlinks
ln -sv /proc/self/mounts /etc/mtab

cat >/etc/hosts <<EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat >/etc/passwd <<"EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat >/etc/group <<"EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# generate C.UTF-8 locale
localedef -i C -f UTF-8 C.UTF-8

# creating a tester user
echo "tester:x:101:101::/home/tester:/bin/bash" >>/etc/passwd
echo "tester:x:101:" >>/etc/group
install -o tester -d /home/tester

# reload the profile for the above changes to take effect
exec /usr/bin/bash --login

# create the necessary log files and fix their permissions
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp

InstallGettext() {
    ./configure --disable-shared
    make
    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
}

InstallBison() {
    ./configure --prefix=/usr \
        --docdir=/usr/share/doc/bison-3.8.2
    make
    make install
}
InstallPerl() {
    sh Configure -des \
        -D prefix=/usr \
        -D vendorprefix=/usr \
        -D useshrplib \
        -D privlib=/usr/lib/perl5/5.40/core_perl \
        -D archlib=/usr/lib/perl5/5.40/core_perl \
        -D sitelib=/usr/lib/perl5/5.40/site_perl \
        -D sitearch=/usr/lib/perl5/5.40/site_perl \
        -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
        -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
    make
    make install
}

installPython() {
    ./configure --prefix=/usr \
        --enable-shared \
        --without-ensurepip
    make
    make install
}

installTexinfo() {
    ./configure --prefix=/usr
    make
    make install
}

installInstallUtilLinux() {
    mkdir -pv /var/lib/hwclock
    ./configure --libdir=/usr/lib \
        --runstatedir=/run \
        --disable-chfn-chsh \
        --disable-login \
        --disable-nologin \
        --disable-su \
        --disable-setpriv \
        --disable-runuser \
        --disable-pylibmount \
        --disable-static \
        --disable-liblastlog2 \
        --without-python \
        ADJTIME_PATH=/var/lib/hwclock/adjtime \
        --docdir=/usr/share/doc/util-linux-2.40.2
    make
    make install
}

prepareDir gettext-0.22.5.tar.xz InstallGettext
prepareDir bison-3.8.2.tar.xz InstallBison
prepareDir perl-5.40.0.tar.xz InstallPerl
prepareDir python-3.12.5 InstallPython
prepareDir texinfo-7.1.tar.xz InstallTexinfo
prepareDir util-linux-2.40.2.tar.xz InstallUtilLinux

# Cleaning
rm -rf /usr/share/{info,man,doc}/*
