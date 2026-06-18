#!/bin/bash
# Build and package mpv locally for a single target arch.
# Requires the toolchain produced by build-llvm.sh.
#
# Usage: build-mpv.sh [--march <arch>] [--mtune <cpu>] [buildroot]
#   --march <arch>  LLVM target arch (default: x86-64-v3; e.g. znver3, x86-64)
#   --mtune <cpu>   -mtune for package builds via CLANG_FLAGS (default: none)
#   buildroot       where clang_root/src_packages/build dirs live
#                   (default: the repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

gitdir=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

march="x86-64-v3"
mtune=""
buildroot=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --march)   march="$2"; shift 2 ;;
        --march=*) march="${1#*=}"; shift ;;
        --mtune)   mtune="$2"; shift 2 ;;
        --mtune=*) mtune="${1#*=}"; shift ;;
        -h|--help) usage 0 ;;
        -*)        echo "unknown option: $1" >&2; usage 1 ;;
        *)         buildroot="$1"; shift ;;
    esac
done
[[ -n "$buildroot" ]] || buildroot="$gitdir"
mkdir -p "$buildroot"
buildroot=$(cd "$buildroot" && pwd)

# Derive the x86_64 level suffix exactly like CMakeLists.txt:30-33
#   x86-64-vN -> -vN ,  <other> -> -<other> ,  x86-64 -> (empty)
if [[ $march =~ ^x86-64(-.+)$ ]]; then
    suffix="${BASH_REMATCH[1]}"
elif [[ $march != "x86-64" ]]; then
    suffix="-$march"
else
    suffix=""
fi

build_dir="$buildroot/build_x86_64$suffix"
mingw_prefix="$build_dir/x86_64$suffix-w64-mingw32"
clang_root="$buildroot/clang_root"
release="$gitdir/release"

if [[ ! -x "$clang_root/bin/clang" ]]; then
    echo "toolchain not found at $clang_root/bin/clang -- run build-llvm.sh first" >&2
    exit 1
fi

clang_flags=""
if [[ -n "$mtune" ]]; then clang_flags="-mtune=$mtune"; fi

echo ">> [1/5] Configuring mpv ($march${mtune:+, -mtune=$mtune}) in $build_dir"
cmake \
    -DTARGET_ARCH=x86_64-w64-mingw32 \
    -DCOMPILER_TOOLCHAIN=clang \
    -DLLVM_ARCH="$march" \
    -DCMAKE_INSTALL_PREFIX="$clang_root" \
    -DMINGW_INSTALL_PREFIX="$mingw_prefix" \
    -DSINGLE_SOURCE_LOCATION="$buildroot/src_packages" \
    -DRUSTUP_LOCATION="$clang_root/install_rustup" \
    -DENABLE_CCACHE=ON \
    -DCLANG_PACKAGES_LTO=ON \
    -DCLANG_FLAGS="$clang_flags" \
    -G Ninja --fresh -B "$build_dir" -S "$gitdir"

echo ">> [2/5] Downloading sources"
ninja -C "$build_dir" download || true

echo ">> [3/5] Updating git packages"
ninja -C "$build_dir" update

echo ">> [4/5] Building mpv"
ninja -C "$build_dir" mpv

echo ">> [5/5] Packaging"
mkdir -p "$release"
ninja -C "$build_dir" mpv-packaging
mv "$build_dir"/mpv*.7z "$release"/ 2>/dev/null || true

ffmpeg_hash=$(git -C "$buildroot/src_packages/ffmpeg" rev-parse --short HEAD)
7z a -m0=lzma2 -mx=9 -ms=on \
    "$release/ffmpeg-x86_64$suffix-git-$ffmpeg_hash.7z" \
    "$mingw_prefix/bin/ffmpeg.exe"

echo ">> Done. Artifacts in $release"
ls -1 "$release"
