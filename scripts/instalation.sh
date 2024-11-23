#!/bin/bash

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:$PATH

prepareDir() {
    echo "------------ Preparing Dir -----------"
    echo "Preparing $PWD/$1"
    dir=$(tar -tf "$1" | head -1 | cut -f1 -d"/")
    echo "cd Into Directory: $dir"
    tar -xvf $1
    pushd "$PWD/$dir"
    $2
    popd
    rm -rf "$PWD/$dir"
    echo "------------ *************** -----------"
}

installBinUtils() {
    mkdir -v build
    pushd build
    ../configure --prefix=$LFS/tools \
        --with-sysroot=$LFS \
        --target=$LFS_TGT \
        --disable-nls \
        --enable-gprofng=no \
        --disable-werror \
        --enable-new-dtags \
        --enable-default-hash-style=gnu
    make
    make install
    popd
}

IntallGcc() {
    tar -xf ../mpfr-4.2.1.tar.xz
    mv -v mpfr-4.2.1 mpfr
    tar -xf ../gmp-6.3.0.tar.xz
    mv -v gmp-6.3.0 gmp
    tar -xf ../mpc-1.3.1.tar.gz
    mv -v mpc-1.3.1 mpc

    case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
        ;;
    esac

    mkdir -v build
    pushd build

    ../configure \
        --target=$LFS_TGT \
        --prefix=$LFS/tools \
        --with-glibc-version=2.40 \
        --with-sysroot=$LFS \
        --with-newlib \
        --without-headers \
        --enable-default-pie \
        --enable-default-ssp \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --disable-threads \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libstdcxx \
        --enable-languages=c,c++

    make
    make install

    popd

    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        $(dirname $($LFS_TGT-gcc -print-libgcc-file-name))/include/limits.h
}

InstallLinuxApiHeaders() {
    make mrproper
    make headers
    find usr/include -type f ! -name '*.h' -delete
    cp -rv usr/include $LFS/usr
}

InstallGlibc() {
    case $(uname -m) in
    i?86)
        ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
        ;;
    x86_64)
        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
        ;;
    esac

    mkdir -v build
    pushd build

    ../configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(../scripts/config.guess) \
        --enable-kernel=4.19 \
        --with-headers=$LFS/usr/include \
        --disable-nscd \
        libc_cv_slibdir=/usr/lib

    make
    make DESTDIR=$LFS install
    sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

    echo "Testing if the new toolchain are working as expected"
    echo 'int main(){}' | $LFS_TGT-gcc -xc -
    readelf -l a.out | grep ld-linux
    rm -v a.out
    echo "End of Test"
    popd
}

installLibstdc() {
    echo "installLibstdc ..."
    mkdir build
    pushd build
    ../libstdc++-v3/configure \
        --host=$LFS_TGT \
        --build=$(../config.guess) \
        --prefix=/usr \
        --disable-multilib \
        --disable-nls \
        --disable-libstdcxx-pch \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
    make
    make DESTDIR=$LFS install
    rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
    popd

}

installM4() {

    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installNcurses() {
    sed -i s/mawk// configure
    mkdir build
    pushd build
    ../configure
    make -C include
    make -C progs tic
    popd
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(./config.guess) \
        --mandir=/usr/share/man \
        --with-manpage-format=normal \
        --with-shared \
        --without-normal \
        --with-cxx-shared \
        --without-debug \
        --without-ada \
        --disable-stripping
    make
    make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
    ln -sv libncursesw.so $LFS/usr/lib/libncurses.so

    sed -e 's/^#if.*XOPEN.*$/#if 1/' \
        -i $LFS/usr/include/curses.h
}

installbash() {
    ./configure --prefix=/usr \
        --build=$(sh support/config.guess) \
        --host=$LFS_TGT \
        --without-bash-malloc \
        bash_cv_strtold_broken=no
    make
    make DESTDIR=$LFS install
    ln -sv bash $LFS/bin/sh
}

installCoreutils() {
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime
    make
    make DESTDIR=$LFS install

    mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
    mkdir -pv $LFS/usr/share/man/man8
    mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8
}

installDiffutils() {
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(./build-aux/config.guess)

    make
    make DESTDIR=$LFS install
}

installFile() {
    mkdir build
    pushd build
    ../configure --disable-bzlib \
        --disable-libseccomp \
        --disable-xzlib \
        --disable-zlib
    make
    popd
    ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
    make FILE_COMPILE=$(pwd)/build/src/file
    make DESTDIR=$LFS install
    rm -v $LFSusr/lib/libmagic.la
}

installFindUtils() {
    ./configure --prefix=/usr \
        --localstatedir=/var/lib/locate \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installGawk() {
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installGrep() {
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(./build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installGzip() {
    ./configure --prefix=/usr --host=$LFS_TGT
    make
    make DESTDIR=$LFS install
}

installMake() {
    ./configure --prefix=/usr \
        --without-guile \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installPatch() {
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installSed() {
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(./build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installTar() {
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(./build-aux/config.guess)
    make
    make DESTDIR=$LFS install
}

installXz() {

    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
        --disable-static \
        --docdir=/usr/share/doc/xz-5.6.2
    make
    make DESTDIR=$LFS install
    rm -v $LFS/usr/lib/liblzma.la

}

installFinalBinUtils() {
    sed '6009s/$add_dir//' -i ltmain.sh
    mkdir -vp build
    pushd build
    ../configure \
        --prefix=/usr \
        --build=$(../config.guess) \
        --host=$LFS_TGT \
        --disable-nls \
        --enable-shared \
        --enable-gprofng=no \
        --disable-werror \
        --enable-64-bit-bfd \
        --enable-new-dtags \
        --enable-default-hash-style=gnu
    popd
    make
    make DESTDIR=$LFS install

    rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
}

installGccpass2() {
    tar -xf ../mpfr-4.2.1.tar.xz
    mv -v mpfr-4.2.1 mpfr
    tar -xf ../gmp-6.3.0.tar.xz
    mv -v gmp-6.3.0 gmp
    tar -xf ../mpc-1.3.1.tar.gz
    mv -v mpc-1.3.1 mpc

    case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
        ;;
    esac

    mkdir -vp build
    pushd ./build
    ../configure \
        --build=$(../config.guess) \
        --host=$LFS_TGT \
        --target=$LFS_TGT \
        LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
        --prefix=/usr \
        --with-build-sysroot=$LFS \
        --enable-default-pie \
        --enable-default-ssp \
        --disable-nls \
        --disable-multilib \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libvtv \
        --enable-languages=c,c++
    make
    make DESTDIR=$LFS install
    ln -sv gcc $LFS/usr/bin/cc
    popd
}

askForPermission() {
    echo $1
    # read -n 1 -s -r -p "Press any key to continue ..."
}

echo "LFS ${LFS:?}"
echo "*** Instlation Of Necessary Packages ***"

pushd $LFS/sources
askForPermission "Compiling a Cross-Toolchain."

# chp5: Compiling a Cross-Toolchain

askForPermission "Installing BinUtils."
prepareDir binutils-2.43.1.tar.xz installBinUtils

askForPermission "Installing GCC."
prepareDir gcc-14.2.0.tar.xz IntallGcc

askForPermission "Installing Linux API Headers."
prepareDir linux-6.10.5.tar.xz InstallLinuxApiHeaders

askForPermission "Installing Glibc."
prepareDir glibc-2.40.tar.xz InstallGlibc

askForPermission "Installing Libstdc."
prepareDir gcc-14.2.0.tar.xz installLibstdc


export PATH=$LFS/tools/bin:$PATH

#chap6: Cross Compiling Temporary Tools
askForPermission "Cross Compiling Temporary Tools."

askForPermission "Installing M4."
prepareDir m4-1.4.19.tar.xz installM4

askForPermission "Installing Ncurses."
prepareDir ncurses-6.5.tar.gz installNcurses

askForPermission "Installing Bash."
prepareDir bash-5.2.32.tar.gz installbash

askForPermission "Installing Coreutils."
prepareDir coreutils-9.5.tar.xz installCoreutils

askForPermission "Installing Diffutils."
prepareDir diffutils-3.10.tar.xz installDiffutils

askForPermission "Installing File."
prepareDir file-5.45.tar.gz installFile

askForPermission "Installing FindUtils."
prepareDir findutils-4.10.0.tar.xz installFindUtils

askForPermission "Installing Gawk."
prepareDir gawk-5.3.0.tar.xz installGawk

askForPermission "Installing Grep."
prepareDir grep-3.11.tar.xz installGrep

askForPermission "Installing Gzip."
prepareDir gzip-1.13.tar.xz installGzip

askForPermission "Installing Make."
prepareDir make-4.4.1.tar.gz installMake

askForPermission "Installing Patch."
prepareDir patch-2.7.6.tar.xz installPatch

askForPermission "Installing Sed."
prepareDir sed-4.9.tar.xz installSed

askForPermission "Installing Tar."
prepareDir tar-1.35.tar.xz installTar

askForPermission "Installing Xz."
prepareDir xz-5.6.2.tar.xz installXz

askForPermission "Installing BinUtils. Pass 2"
prepareDir binutils-2.43.1.tar.xz installFinalBinUtils

askForPermission "Installing GCC. Pass 2"
prepareDir gcc-14.2.0.tar.xz installGccpass2
popd
