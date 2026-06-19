#!/bin/bash
# Build the LLVM/Clang + Rust cross toolchain from scratch for a single target
# arch. The result is installed to clang_root. Run before build-mpv.sh.
#
# Usage: build-llvm.sh [--march <arch>] [buildroot]
#   --march <arch>  LLVM target arch (default: x86-64-v3; e.g. znver3, x86-64)
#   buildroot       where clang_root/src_packages/build dirs live
#                   (default: the repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

gitdir=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

march="x86-64-v3"
buildroot=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --march)   march="$2"; shift 2 ;;
        --march=*) march="${1#*=}"; shift ;;
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

host_dir="$buildroot/build_x86_64"
arch_dir="$buildroot/build_x86_64$x86_64_level"
clang_root="$buildroot/clang_root"
profdata="$buildroot/llvm.profdata"

echo ">> Wiping build dirs + clang_root for a from-scratch rebuild"
rm -rf "$host_dir" "$arch_dir" "$clang_root" "$profdata"

common=(
    -DTARGET_ARCH=x86_64-w64-mingw32
    -DCOMPILER_TOOLCHAIN=clang
    -DCMAKE_INSTALL_PREFIX="$clang_root"
    -DSINGLE_SOURCE_LOCATION="$buildroot/src_packages"
    -DRUSTUP_LOCATION="$clang_root/install_rustup"
    -G Ninja
    -S "$gitdir"
)

src_packages=(llvm mingw-w64 cppwinrt)

refresh_sources() { # $1 = build dir exposing the <pkg>-force-update targets
    local dir=$1 pkg targets=() names=()
    for pkg in "${src_packages[@]}"; do
        if [[ -d "$buildroot/src_packages/$pkg/.git" ]]; then
            targets+=("$pkg-force-update"); names+=("$pkg")
        fi
    done
    if [[ ${#targets[@]} -gt 0 ]]; then
        echo ">> Fast-forwarding toolchain sources: ${names[*]}"
        ninja -C "$dir" "${targets[@]}"
    fi
}

echo ">> [1/6] Build LLVM with PGO"
cmake "${common[@]}" -DLLVM_ENABLE_PGO=GEN \
    -DMINGW_INSTALL_PREFIX="$host_dir/x86_64-w64-mingw32" -B "$host_dir"
refresh_sources "$host_dir"
ninja -C "$host_dir" llvm
ninja -C "$host_dir" rustup
ninja -C "$host_dir" cargo-clean

echo ">> [2/6] Build x86_64 cross toolchain"
ninja -C "$host_dir" llvm-clang

if [[ -n "$x86_64_level" ]]; then
    echo ">> [3/6] Build $march cross toolchain"
    cmake "${common[@]}" -DLLVM_ARCH="$march" \
        -DMINGW_INSTALL_PREFIX="$arch_dir/x86_64$x86_64_level-w64-mingw32" -B "$arch_dir"
    ninja -C "$arch_dir" llvm-clang
else
    echo ">> [3/6] skipped ($march is the base toolchain)"
fi

echo ">> [4/6] PGO training with shaderc"
cmake "${common[@]}" -DLLVM_ENABLE_PGO=GEN -DCLANG_PACKAGES_LTO=ON \
    -DMINGW_INSTALL_PREFIX="$host_dir/x86_64-w64-mingw32" -B "$host_dir"
ninja -C "$host_dir" shaderc

echo ">> [5/6] Merging profraw -> $profdata"
llvm-profdata merge "$clang_root"/profiles/*.profraw -o "$profdata"
rm -rf "$clang_root"/profiles/* || true

echo ">> [6/6] Rebuilding LLVM with PGO"
cmake "${common[@]}" -DLLVM_ENABLE_PGO=USE -DLLVM_PROFDATA_FILE="$profdata" \
    -DMINGW_INSTALL_PREFIX="$host_dir/x86_64-w64-mingw32" -B "$host_dir"
ninja -C "$host_dir" llvm

echo ">> Toolchain ready: $clang_root (arch sysroot: $arch_dir)"
