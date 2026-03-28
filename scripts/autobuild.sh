#!/bin/bash
# Automatically build mpv for x86_64_v3

main() {
    gitdir=$(pwd)

    if [ -z "$1" ]; then
        buildroot=$(pwd)
    else
        buildroot=$1
    fi
    build
    zip
}

build() {
    mkdir -p $buildroot/build
    cmake -DTARGET_ARCH=x86_64-w64-mingw32 -DCOMPILER_TOOLCHAIN=clang -DLLVM_ARCH=x86-64-v3 -DCMAKE_INSTALL_PREFIX=$buildroot/clang_root -DMINGW_INSTALL_PREFIX=$buildroot/build/x86_64-v3-w64-mingw32 -DSINGLE_SOURCE_LOCATION=$buildroot/src_packages -DRUSTUP_LOCATION=$buildroot/clang_root/install_rustup -DCLANG_PACKAGES_LTO=ON -G Ninja -H$gitdir -B$buildroot/build
    ninja -C $buildroot/build update
    ninja -C $buildroot/build mpv

    if [ -d $buildroot/build/mpv-x86_64-v3-* ] ; then
        echo "Successfully compiled. Continue"
    else
        echo "Failed to compile. Stop"
        exit 1
    fi
}

zip() {
    mkdir -p $gitdir/release
    cd $gitdir/release

    # mpv
    mv $buildroot/build/mpv-x86_64-v3-* .
    for dir in ./mpv-x86_64-v3-*; do
        if [ -d $dir ]; then
            7z a -m0=lzma2 -mx=9 -ms=on $dir.7z $dir/* -x!*.7z
            rm -rf $dir
        fi
    done

    # ffmpeg
    hash=$(git -C $buildroot/src_packages/ffmpeg rev-parse --short HEAD)
    cp $buildroot/build/x86_64-v3-w64-mingw32/bin/ffmpeg.exe .
    7z a -m0=lzma2 -mx=9 -ms=on ffmpeg-x86_64-v3-git-$hash.7z ffmpeg.exe
    rm -f ffmpeg.exe

    cd ..
}

cd $(dirname `realpath $0`)/..
main $1
