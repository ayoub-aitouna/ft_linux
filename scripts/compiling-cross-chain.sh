prepareDir() {
    echo "Preparing $PWD/$1"
    dir=$(tar -tf "$1" | head -1 | cut -f1 -d"/")
    tar -xf $1
    pushd $PWD/$dir
    $2
    popd
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
    make install

    case $(uname -m) in
    i?86)
        ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
        ;;
    x86_64)
        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
        ;;
    esac
    popd

}

echo "LFS ${LFS:?}"
ls -la $LFS

pushd $LFS/sources
# prepareDir binutils-2.43.1.tar.xz installBinUtils
prepareDir gcc-14.2.0.tar.xz IntallGcc
prepareDir linux-6.10.5.tar.xz InstallLinuxApiHeaders
popd
