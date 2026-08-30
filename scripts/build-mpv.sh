#!/bin/bash
# Build and package mpv for a target CPU.
# Requires the toolchain from build-llvm.sh. Packaged .7z artifacts are written to release/.
#
# Usage: build-mpv.sh [--march <cpu>] [--mtune <cpu>] [buildroot]
#   --march <cpu>   target CPU for -march (default: x86-64-v3; e.g. znver3, x86-64).
#                   The arch stays x86_64; this is a psABI level or a CPU name.
#   --mtune <cpu>   -mtune for package builds via CLANG_FLAGS (default: none)
#   buildroot       location of the clang_root/src_packages/build dirs
#                   (default: the repository root)
set -euo pipefail
shopt -s nullglob

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

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
        -*)        echo "Unknown option: $1" >&2; usage 1 ;;
        *)         buildroot="$1"; shift ;;
    esac
done
[[ -n "$buildroot" ]] || buildroot="$repo_root"
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

march_dir="$buildroot/build_x86_64$x86_64_level"
sysroot="$march_dir/x86_64$x86_64_level-w64-mingw32"
clang_root="$buildroot/clang_root"
release_dir="$buildroot/release"

if [[ ! -d "$sysroot/include" || ! -d "$sysroot/lib" ]]; then
    echo "Sysroot not found at $sysroot -- run build-llvm.sh first" >&2
    exit 1
fi

if [[ ! -x "$clang_root/bin/clang" ]]; then
    echo "Toolchain not found at $clang_root/bin/clang -- run build-llvm.sh first" >&2
    exit 1
fi

clang_flags=""
if [[ -n "$mtune" ]]; then clang_flags="-mtune=$mtune"; fi

echo ">> [1/6] Configure mpv ($march${mtune:+, -mtune=$mtune}) in $march_dir"
cmake \
    -DTARGET_ARCH=x86_64-w64-mingw32 \
    -DCOMPILER_TOOLCHAIN=clang \
    -DLLVM_ARCH="$march" \
    -DCMAKE_INSTALL_PREFIX="$clang_root" \
    -DMINGW_INSTALL_PREFIX="$sysroot" \
    -DSINGLE_SOURCE_LOCATION="$buildroot/src_packages" \
    -DRUSTUP_LOCATION="$clang_root/install_rustup" \
    -DENABLE_CCACHE=ON \
    -DCLANG_PACKAGES_LTO=ON \
    -DCLANG_FLAGS="$clang_flags" \
    -G Ninja --fresh -B "$march_dir" -S "$repo_root"

echo ">> [2/6] Download sources"
ninja -C "$march_dir" download || true

echo ">> [3/6] Update git packages"
ninja -C "$march_dir" update

echo ">> [4/6] Build mpv"
ninja -C "$march_dir" mpv

echo ">> [5/6] Package mpv"
mkdir -p "$release_dir"
ninja -C "$march_dir" mpv-packaging
archives=("$march_dir"/mpv*.7z)
[[ ${#archives[@]} -gt 0 ]] || { echo "No archive from mpv-packaging in $march_dir" >&2; exit 1; }
mv "${archives[@]}" "$release_dir"/
produced=("${archives[@]##*/}")

ffmpeg_hash=$(git -C "$buildroot/src_packages/ffmpeg" rev-parse --short HEAD)
ffmpeg_archive="ffmpeg-x86_64$x86_64_level-git-$ffmpeg_hash.7z"
7z a -m0=lzma2 -mx=9 -ms=on \
    "$release_dir/$ffmpeg_archive" \
    "$sysroot/bin/ffmpeg.exe"
produced+=("$ffmpeg_archive")

echo ">> [6/6] Clean cargo cache"
ninja -C "$march_dir" cargo-clean

echo ">> Artifacts: $release_dir"
printf '%s\n' "${produced[@]}"
