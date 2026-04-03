# CMake-based MinGW-w64 Cross Toolchain

This fork is tailored for typical playback scenarios, removing video/audio encoding libraries, legacy formats, specialized formats, and rare protocol support.
Encoding libraries (x264, x265, aom, lame, opus, flac, etc.) are only needed for encoding/transcoding — **FFmpeg's decoding and playback functionality remains fully intact.**
Image encoding is limited to jpg, webp, and png via libjpeg, libwebp, and libpng.
Only Vulkan and Direct3D 11+ are supported for GPU acceleration, with nvcodec.

Autobuild runs daily at UTC 00:00.

For easy updates: [sohnyj/app-updater](https://github.com/sohnyj/app-updater)

## What's removed

- **Video** — x264, x265, aom, svtav1, uavs3d, davs2, libvpx, xvidcore, avisynth-headers, vapoursynth
- **Audio** — lame, opus (with libopusenc, opusfile, opus-tools, opus-dnn), flac, vorbis, ogg, speex, libopenmpt, libmodplug, game-music-emu, libmysofa, libbs2b, openal-soft, rubberband (with fftw3, libsamplerate)
- **Image** — libjxl (and highway)
- **Subtitle** — libaribcaption, libzvbi
- **Disc playback** — libdvdcss, libdvdread, libdvdnav, libudfread
- **Network** — curl, libssh, libsrt, megasdk (with cryptopp, libsodium, libuv, sqlite, readline, termcap)
- **Graphics** — ANGLE headers
- **Hardware acceleration** — amf-headers, libmfx, libva, libvpl
- **Scripting** — mujs
- **Input** — libsdl2
- **Compression** — xz (LZMA), lzo
- **Misc** — libsixel

GCC toolchain support is also removed; only Clang/LLD is supported.

## Minimum Requirements

- **OS**: Windows 10 or later
- **CPU**: x86_64-v3 (AVX2 support required, e.g. Intel Haswell / AMD Excavator or newer)

## Prerequisites

 -  You should install Ninja and use CMake's Ninja build file generator.
    It's not only much faster than GNU Make, but also far less error-prone,
    which is important for this project because CMake's ExternalProject module
    tends to generate makefiles which confuse GNU Make's jobserver thingy.

 -  As a build environment, any modern Linux distribution *should* work.

## Setup Build Environment
### Ubuntu Linux / WSL (Windows 10)

    apt-get install build-essential git ninja-build cmake automake pkgconf libtool libtool-bin clang llvm lld libc++1 libc++abi1 libgmp-dev libmpfr-dev libmpc-dev libgcrypt-dev python3-pip unzip p7zip-full curl ccache gettext nasm

    pip3 install --break-system-packages meson mako jsonschema

## Compiling with Clang

Example:

    cmake -DTARGET_ARCH=x86_64-w64-mingw32 \
    -DCMAKE_INSTALL_PREFIX="/home/USER/clang_root" \
    -DLLVM_ARCH=x86-64-v3 \
    -DSINGLE_SOURCE_LOCATION="/home/USER/packages" \
    -DRUSTUP_LOCATION="/home/USER/install_rustup" \
    -DMINGW_INSTALL_PREFIX="/home/USER/build_x86_64-v3/x86_64-v3-w64-mingw32" \
    -G Ninja -B build_x86_64-v3 -S minimal-mpv-winbuild

The cmake command will create `clang_root` as clang sysroot where LLVM tools are installed. `build_x86_64-v3` is the build directory for compiling packages.

    cd build_x86_64-v3
    ninja llvm       # build LLVM (takes ~2 hours)
    ninja rustup     # build rust toolchain
    ninja llvm-clang # build clang on specified target
    ninja mpv        # build mpv and all its dependencies

`-DLLVM_ARCH=x86-64-v3` will set the `-march` option to `x86-64-v3` instructions. Other values like `native`, `znver3` should work too.

## Building Software (Second Time)

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
    - brotli
    - bzip2
    - dav1d
    - expat
    - FFmpeg
    - fontconfig
    - freetype2
    - fribidi
    - harfbuzz
    - lcms2
    - libarchive
    - libass
    - libbluray
    - libjpeg
    - libplacebo (with glad, fast_float, xxhash)
    - libpng
    - libsoxr
    - libunibreak
    - libwebp
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
    - zlib (zlib-ng)
    - zstd

- Tarball
    - libiconv (1.19)

## Acknowledgements

This project was originally created by [lachs0r](https://github.com/lachs0r/mingw-w64-cmake) and heavily modified by [shinchiro](https://github.com/shinchiro/mpv-winbuild-cmake). This fork is a minimal build trimmed down for personal use.
