#!/bin/bash
# Build and package mpv for a target arch.
# Requires the toolchain from build-llvm.sh. Packaged .7z artifacts land in release/.
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

# Derive x86_64_level exactly like CMakeLists.txt's x86_64_LEVEL
#   x86-64-vN -> -vN ,  <other> -> -<other> ,  x86-64 -> (empty)
if [[ $march =~ ^x86-64(-.+)$ ]]; then
    x86_64_level="${BASH_REMATCH[1]}"
elif [[ $march != "x86-64" ]]; then
    x86_64_level="-$march"
else
    x86_64_level=""
fi

arch_dir="$buildroot/build_x86_64$x86_64_level"
mingw_prefix="$arch_dir/x86_64$x86_64_level-w64-mingw32"
clang_root="$buildroot/clang_root"
release_dir="$gitdir/release"

if [[ ! -x "$clang_root/bin/clang" ]]; then
    echo "toolchain not found at $clang_root/bin/clang -- run build-llvm.sh first" >&2
    exit 1
fi

clang_flags=""
if [[ -n "$mtune" ]]; then clang_flags="-mtune=$mtune"; fi

echo ">> [1/6] Configuring mpv ($march${mtune:+, -mtune=$mtune}) in $arch_dir"
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
    -G Ninja --fresh -B "$arch_dir" -S "$gitdir"

echo ">> [2/6] Downloading sources"
ninja -C "$arch_dir" download || true

echo ">> [3/6] Updating git packages"
ninja -C "$arch_dir" update

echo ">> [4/6] Building mpv"
ninja -C "$arch_dir" mpv

echo ">> [5/6] Packaging mpv"
mkdir -p "$release_dir"
ninja -C "$arch_dir" mpv-packaging
mv "$arch_dir"/mpv*.7z "$release_dir"/ 2>/dev/null || true

ffmpeg_hash=$(git -C "$buildroot/src_packages/ffmpeg" rev-parse --short HEAD)
7z a -m0=lzma2 -mx=9 -ms=on \
    "$release_dir/ffmpeg-x86_64$x86_64_level-git-$ffmpeg_hash.7z" \
    "$mingw_prefix/bin/ffmpeg.exe"

echo ">> [6/6] Cleaning Rust build artifacts"
ninja -C "$arch_dir" cargo-clean

echo ">> Artifacts: $release_dir"
ls -1 "$release_dir"
