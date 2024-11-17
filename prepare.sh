#!/bin/bash

# echo "DIST ROOT ${DIST:?}"
echo "LFS ${LFS:?}"
ls -la $LFS

#preparing the partion and dir
PrepareDir(){
    sudo mount -v -t ext4 /dev/sdb1 $LFS
    sudo mkdir -v $LFS/sources
    sudo chmod -v a+wt $LFS/sources
}

#preparing the needed packages
PreparePackages()
{
    wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
    pushd $LFS/sources
    md5sum -c ../md5sums
    popd
    sudo chown root:root $LFS/sources/*
}

PrepareFs()
{
    sudo mkdir -vp $LFS/{etc,var} $LFS/usr/{lib,sbin,bin}
    for i in bin lib sbin; do
        sudo ln -sv usr/$i $LFS/$i
    done

    case $(uname -m) in
        x86_64) sudo mkdir -pv $LFS/lib64 ;;
    esac
    sudo mkdir -pv $LFS/tools
}


AddingLfsUser()
{
    sudo groupadd lfs
    sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
    echo "lfs:1122" | sudo chpasswd
    sudo chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
    sudo cp ./setupenv.sh /home/lfs/
    [ ! -e /etc/bash.bashrc ] || sudo mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
    case $(uname -m) in
        x86_64) sudo chown -v lfs $LFS/lib64 ;;
    esac
    su - lfs
}

AddingLfsUser
