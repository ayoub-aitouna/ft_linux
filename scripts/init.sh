#!/bin/bash

LFS='/mnt/lfs'
download=0
username=lfs

echo "LFS ${LFS:?}"

if [ ! -e $LFS ]; then
    sudo mkdir -p $LFS
fi

ls -la $LFS

#preparing the partion and dir
PrepareDir() {
    if ! mountpoint -q $LFS; then
        sudo mount -v -t ext4 /dev/sdb1 $LFS
    else
        echo "/mnt/lfs is already mounted"
    fi
    if [ ! -d $LFS/sources ]; then
        sudo mkdir -v $LFS/sources
    else
        echo "$LFS/sources is already exist"
    fi

    sudo chmod -v a+wt $LFS/sources
}

#preparing the needed packages
PreparePackages() {
    echo "Downloading Packages"

    if [ ! $download -eq 1 ]; then
        echo "Download is disabled"
        return
    fi
    wget --input-file=source/wget-list-sysv --continue --directory-prefix=$LFS/sources
    pushd $LFS/sources
    md5sum -c ../md5sums
    popd
    sudo chown root:root $LFS/sources/*
}

PrepareFs() {
    if [ -e $LFS/usr -a -e $LFS/lib -a -e $LFS/var -a -e $LFS/etc -a -e $LFS/bin -a -e $LFS/sbin -a -e $LFS/tools ]; then
        echo "Filesystem is already prepared"
        return
    fi

    sudo mkdir -vp $LFS/{etc,var} $LFS/usr/{lib,sbin,bin}
    for i in bin lib sbin; do
        sudo ln -sv usr/$i $LFS/$i
    done

    case $(uname -m) in
    x86_64) sudo mkdir -pv $LFS/lib64 ;;
    esac
    sudo mkdir -pv $LFS/tools
}

AddingLfsUser() {
    sudo userdel -r $username

    echo "Creating $username USER"
    sudo groupadd $username
    sudo useradd -s /bin/bash -g $username -m -k /dev/null $username
    echo "$username:1122" | sudo chpasswd
    sudo chown -v $username $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
    echo "Copying {Scrips/Config} to new UserDir"

    sudo cp -r ./scripts/ /home/$username/
    sudo cp -r ./config/ /home/$username/

    [ ! -e /etc/bash.bashrc ] || sudo mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
    case $(uname -m) in
    x86_64) sudo chown -v $username $LFS/lib64 ;;
    esac

}

PrepareDir
PreparePackages
PrepareFs
AddingLfsUser

echo "Running init-lfs-user.sh"
sudo -u $username -i bash -c "bash /home/$username/scripts/init-lfs-user.sh"
