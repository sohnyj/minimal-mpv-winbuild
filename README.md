# CMake-based MinGW-w64 Cross Toolchain

This fork is tailored for typical playback scenarios, removing video/audio encoding libraries, legacy formats, specialized formats, and rare protocol support.
Encoding libraries are only needed for encoding/transcoding, not playback. Image encoding is limited to png, jpg, and jxl.

Only Vulkan and Direct3D 11 are supported for GPU acceleration, with nvidia(nvcodec-headers), amd(amf-headers), and intel(libvpl).

Autobuild runs daily at UTC 00:00.

- easy updates: [sohnyj/app-updater](https://github.com/sohnyj/app-updater)
- single-instance mpv launcher: [sohnyj/umpv-rs](https://github.com/sohnyj/umpv-rs)

## What's removed

- **Video** — x264, x265, aom, svtav1, uavs3d, davs2, libvpx, xvidcore, avisynth-headers, vapoursynth
- **Audio** — lame, opus (with libopusenc, opusfile, opus-tools, opus-dnn), flac, vorbis, ogg, speex, libopenmpt, libmodplug, game-music-emu, libmysofa, libbs2b, openal-soft, rubberband (with libsamplerate)
- **Image** — libwebp
- **Subtitle** — libaribcaption, libzvbi
- **Font** — fontconfig
- **Disc playback** — libdvdcss, libdvdread, libdvdnav
- **Network** — libssh, libsrt, megasdk (with cryptopp, libsodium, libuv, sqlite, readline, termcap)
- **Graphics** — ANGLE headers
- **Hardware acceleration** — libmfx, libva
- **Scripting** — mujs
- **Input** — libsdl2
- **Compression** — lzo
- **Misc** — libsixel

GCC toolchain support is also removed; only Clang/LLD is supported.

## Minimum Requirements

- **OS**: Windows 10 or later
- **CPU**: x86_64-v3 (AVX2 support required)

## Prerequisites

 -  You should install Ninja and use CMake's Ninja build file generator.
    It's not only much faster than GNU Make, but also far less error-prone,
    which is important for this project because CMake's ExternalProject module
    tends to generate makefiles which confuse GNU Make's jobserver thingy.

## Setup Build Environment
### Ubuntu Linux 24.04+ / WSL2

    apt install automake autopoint build-essential ccache clang cmake curl gettext git glslang-tools libc++-dev libc++1 libc++abi-dev libc++abi1 libgcrypt-dev libgmp-dev libmimalloc-dev libmpc-dev libmpfr-dev libtool libtool-bin lld llvm nasm ninja-build p7zip-full pkgconf python3-jsonschema python3-mako python3-pip unzip

    pip3 install --break-system-packages meson

pip installs `meson` into `~/.local/bin`, so make sure that directory is on your `PATH`.

    export PATH="$HOME/.local/bin:$PATH"

## Build scripts

The `scripts/` directory automates the manual toolchain and mpv builds described below.

| Script | Purpose |
| ------ | ------- |
| `build-llvm.sh` | Build the LLVM/Clang + Rust toolchain from scratch with PGO. Run before `build-mpv.sh`. |
| `build-mpv.sh` | Build and package mpv + ffmpeg against that toolchain into `./release`. |
| `update-repo.sh` | Force-update git-based package sources. |
| `clean-repo.sh` | Reset git-based package sources for a fresh re-clone. |

    build-llvm.sh                                # toolchain (default: x86-64-v3)
    build-mpv.sh                                 # mpv + ffmpeg
    build-llvm.sh --march znver3                 # other arch
    build-mpv.sh  --march znver3 --mtune znver3

Each takes an optional trailing `buildroot` (the directory holding `clang_root`/`src_packages`/`build_*`), defaulting to the repository root.

## Toolchain & mpv build

Example:

    cmake -DTARGET_ARCH=x86_64-w64-mingw32 \
    -DCMAKE_INSTALL_PREFIX="/home/USER/minimal-mpv-winbuild/clang_root" \
    -DLLVM_ARCH=x86-64-v3 \
    -DSINGLE_SOURCE_LOCATION="/home/USER/minimal-mpv-winbuild/src_packages" \
    -DRUSTUP_LOCATION="/home/USER/minimal-mpv-winbuild/install_rustup" \
    -DMINGW_INSTALL_PREFIX="/home/USER/minimal-mpv-winbuild/build_x86_64-v3/x86_64-v3-w64-mingw32" \
    -G Ninja -B minimal-mpv-winbuild/build_x86_64-v3 -S minimal-mpv-winbuild

The cmake command will create `clang_root` as clang sysroot where LLVM tools are installed. `build_x86_64-v3` is the build directory for compiling packages.

    cd minimal-mpv-winbuild/build_x86_64-v3
    ninja llvm       # build LLVM (takes ~2 hours)
    ninja rustup     # build rust toolchain
    ninja llvm-clang # build clang on specified target
    ninja mpv        # build mpv and all its dependencies

`-DLLVM_ARCH=x86-64-v3` will set the `-march` option to `x86-64-v3` instructions. Other values like `native`, `znver3` should work too.

### Incremental mpv build

To build mpv for a second time:

    ninja update # perform git pull on all packages that used git

After that, build mpv as usual:

    ninja mpv

## Available Commands

| Commands                   | Description |
| -------------------------- | ----------- |
| ninja package              | compile a package |
| ninja clean                | remove all stamp files in all packages. |
| ninja download             | Download all packages' sources at once without compiling. |
| ninja update               | Update all git repos. When a package pulls new changes, all of its stamp files will be deleted and will be force-rebuilt. If there is no change, it will not remove the stamp files and no rebuild occurs. Use this instead of `ninja clean` if you don't want to rebuild everything in the next run. |
| ninja package-fullclean    | Remove all stamp files of a package. |
| ninja package-liteclean    | Remove build, clean stamp files only. This will skip re-configure in the next running `ninja package` (after the first compile). Updating repo or patching needs to be done manually. Ideally, all `DEPENDS` targets in `package.cmake` should be temporarily commented or deleted. Might be useful in some cases. |
| ninja package-removebuild  | Remove 'build' directory of a package. |
| ninja package-removeprefix | Remove 'prefix' directory. |
| ninja package-force-update | Update a package. Only git repo will be updated. |

`package` is package's name found in `packages` folder.

## Information about packages

- Git (Nightly)
    - amf-headers
    - brotli
    - bzip2
    - curl (with c-ares, libpsl, nghttp2, nghttp3, ngtcp2)
    - dav1d
    - FFmpeg
    - freetype2
    - fribidi
    - harfbuzz
    - lcms2
    - libarchive
    - libass
    - libbluray (with libudfread)
    - libjpeg
    - libjxl (with highway)
    - libplacebo (with glad, fast_float, xxhash)
    - libpng
    - libsoxr
    - libunibreak
    - libvpl
    - libxml2
    - libzimg (with graphengine)
    - luajit
    - mpv
    - nvcodec-headers
    - openssl
    - shaderc (with spirv-headers, spirv-tools, glslang)
    - spirv-cross
    - subrandr
    - uchardet
    - vulkan
    - vulkan-header
    - xz
    - zlib (zlib-ng)
    - zstd

- Tarball
    - libiconv (1.19)

## Acknowledgements

This project was originally created by [lachs0r](https://github.com/lachs0r/mingw-w64-cmake) and heavily modified by [shinchiro](https://github.com/shinchiro/mpv-winbuild-cmake).
