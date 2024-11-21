#!/bin/bash



echo "LFS ${LFS:?}"
ls -la $LFS

#preparing the partion and dir
PrepareDir() {
    sudo mount -v -t ext4 /dev/sdb1 $LFS
    sudo mkdir -v $LFS/sources
    sudo chmod -v a+wt $LFS/sources
}

#preparing the needed packages
PreparePackages() {
    wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
    pushd $LFS/sources
    md5sum -c ../md5sums
    popd
    sudo chown root:root $LFS/sources/*
}

PrepareFs() {
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
    username=lfs
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
    su - $username
    # sudo -u lfs sh /home/lfs/scripts/init-lfs-user.sh
    # sudo -u lfs -i

}

PrepareDir
# PreparePackages
# PrepareFs
AddingLfsUser
