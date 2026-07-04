#!/bin/bash
# Reset git-based package sources for a fresh re-clone. For each package, ninja
# runs its <pkg>-fullclean and <pkg>-removeprefix.
#
# Usage: clean-repo.sh [-p pkg]... [buildroot]
#   -p, --pkg pkg  package to clean (repeatable; default: every git source clone)
#   buildroot      where src_packages/build dirs live
#                  (default: the repository root)
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

gitdir=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

buildroot=""
pkgs=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--pkg)  pkgs+=("$2"); shift 2 ;;
        --pkg=*)   pkgs+=("${1#*=}"); shift ;;
        -h|--help) usage 0 ;;
        -*)        echo "unknown option: $1" >&2; usage 1 ;;
        *)         buildroot="$1"; shift ;;
    esac
done
[[ -n "$buildroot" ]] || buildroot="$gitdir"
buildroot=$(cd "$buildroot" && pwd)

src_packages="$buildroot/src_packages"
[[ -d "$src_packages" ]] || { echo "No src_packages dir under $buildroot" >&2; exit 1; }

shopt -s nullglob

toolchain_pkgs=" llvm mingw-w64 cppwinrt "

if [[ ${#pkgs[@]} -eq 0 ]]; then
    for d in "$src_packages"/*/; do
        [[ -d "$d.git" ]] && pkgs+=("$(basename "$d")")
    done
fi

filtered=()
for pkg in ${pkgs[@]+"${pkgs[@]}"}; do
    [[ "$toolchain_pkgs" == *" $pkg "* ]] && continue
    filtered+=("$pkg")
done
[[ ${#filtered[@]} -gt 0 ]] || { echo "Nothing to clean under $src_packages" >&2; exit 1; }
pkgs=("${filtered[@]}")

rc=0
for pkg in "${pkgs[@]}"; do
    echo ">> Cleaning $pkg"
    hit=0
    for dir in "$buildroot"/build_x86_64*; do
        [[ -f "$dir/build.ninja" ]] || continue
        ninja -C "$dir" "$pkg-fullclean" || true
        ninja -C "$dir" "$pkg-removeprefix" || rc=1
        hit=1
    done
    [[ $hit -eq 1 ]] || echo ">> no configured build_x86_64* dir found"
done

echo ">> Done."
exit $rc
