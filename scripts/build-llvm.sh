#!/bin/bash
# Build the LLVM/Clang + Rust cross toolchain from scratch for a target arch.
# Installs to clang_root. Run before build-mpv.sh.
#
# Usage: build-llvm.sh [--march <arch>] [buildroot]
#   --march <arch>  LLVM target arch (default: x86-64-v3; e.g. znver3, x86-64)
#   buildroot       where clang_root/src_packages/build dirs live
#                   (default: the repository root)
set -euo pipefail
shopt -s nullglob

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

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

base_dir="$buildroot/build_x86_64"
march_dir="$buildroot/build_x86_64$x86_64_level"
clang_root="$buildroot/clang_root"
profdata="$buildroot/llvm.profdata"

echo ">> Wipe build dirs + clang_root for a from-scratch rebuild"
rm -rf "$base_dir" "$march_dir" "$clang_root" "$profdata"

cmake_args=(
    -DTARGET_ARCH=x86_64-w64-mingw32
    -DCOMPILER_TOOLCHAIN=clang
    -DCMAKE_INSTALL_PREFIX="$clang_root"
    -DSINGLE_SOURCE_LOCATION="$buildroot/src_packages"
    -DRUSTUP_LOCATION="$clang_root/install_rustup"
    -G Ninja
    -S "$repo_root"
)

toolchain_pkgs=(llvm mingw-w64 cppwinrt)

refresh_sources() { # $1 = build dir exposing the <pkg>-force-update targets
    local dir=$1 pkg targets=() names=()
    for pkg in "${toolchain_pkgs[@]}"; do
        if [[ -d "$buildroot/src_packages/$pkg/.git" ]]; then
            targets+=("$pkg-force-update"); names+=("$pkg")
        fi
    done
    if [[ ${#targets[@]} -gt 0 ]]; then
        echo ">> Fast-forward toolchain sources: ${names[*]}"
        ninja -C "$dir" "${targets[@]}"
    fi
}

echo ">> [1/6] Build LLVM with PGO instrumentation"
cmake "${cmake_args[@]}" -DLLVM_ENABLE_PGO=GEN \
    -DMINGW_INSTALL_PREFIX="$base_dir/x86_64-w64-mingw32" -B "$base_dir"
refresh_sources "$base_dir"
ninja -C "$base_dir" llvm
ninja -C "$base_dir" rustup
ninja -C "$base_dir" cargo-clean

echo ">> [2/6] Build x86_64 sysroot"
ninja -C "$base_dir" llvm-clang

if [[ -n "$x86_64_level" ]]; then
    echo ">> [3/6] Build $march sysroot"
    cmake "${cmake_args[@]}" -DLLVM_ARCH="$march" \
        -DMINGW_INSTALL_PREFIX="$march_dir/x86_64$x86_64_level-w64-mingw32" -B "$march_dir"
    ninja -C "$march_dir" llvm-clang
else
    echo ">> [3/6] skipped ($march is the base sysroot)"
fi

echo ">> [4/6] Train PGO with shaderc"
cmake "${cmake_args[@]}" -DLLVM_ENABLE_PGO=GEN -DCLANG_PACKAGES_LTO=ON \
    -DMINGW_INSTALL_PREFIX="$base_dir/x86_64-w64-mingw32" -B "$base_dir"
ninja -C "$base_dir" shaderc

echo ">> [5/6] Merge profraw -> $profdata"
profraw=("$clang_root"/profiles/*.profraw)
[[ ${#profraw[@]} -gt 0 ]] || { echo "no profraw under $clang_root/profiles -- PGO training produced no profile" >&2; exit 1; }
llvm-profdata merge "${profraw[@]}" -o "$profdata"
rm -rf "$clang_root"/profiles/* || true

echo ">> [6/6] Rebuild LLVM with PGO"
cmake "${cmake_args[@]}" -DLLVM_ENABLE_PGO=USE -DLLVM_PROFDATA_FILE="$profdata" \
    -DMINGW_INSTALL_PREFIX="$base_dir/x86_64-w64-mingw32" -B "$base_dir"
ninja -C "$base_dir" llvm

echo ">> Sysroot: $march_dir/x86_64$x86_64_level-w64-mingw32"
echo ">> Toolchain: $clang_root"
