#!/bin/bash
# Reset git-based package sources for a fresh re-clone. For each package, ninja
# runs its <pkg>-fullclean and <pkg>-removeprefix. mingw-w64 is skipped: it is a
# source-only ExternalProject and has neither target.
#
# Usage: clean-repo.sh [-p pkg]... [buildroot]
#   -p, --pkg pkg  package to clean (repeatable; default: every git source clone)
#   buildroot      location of the src_packages/build dirs
#                  (default: the repository root)
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

buildroot=""
pkgs=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--pkg)  pkgs+=("$2"); shift 2 ;;
        --pkg=*)   pkgs+=("${1#*=}"); shift ;;
        -h|--help) usage 0 ;;
        -*)        echo "Unknown option: $1" >&2; usage 1 ;;
        *)         buildroot="$1"; shift ;;
    esac
done
[[ -n "$buildroot" ]] || buildroot="$repo_root"
[[ -d "$buildroot" ]] || { echo "No such directory: $buildroot" >&2; exit 1; }
buildroot=$(cd "$buildroot" && pwd)

src_packages="$buildroot/src_packages"
[[ -d "$src_packages" ]] || { echo "No src_packages dir under $buildroot" >&2; exit 1; }

shopt -s nullglob

# These build nothing and install nothing, so cleanup() is never called for them
# and ninja has no <pkg>-fullclean or <pkg>-removeprefix to run.
source_only_pkgs=(mingw-w64)

is_source_only() {
    local p
    for p in "${source_only_pkgs[@]}"; do
        [[ "$p" == "$1" ]] && return 0
    done
    return 1
}

if [[ ${#pkgs[@]} -eq 0 ]]; then
    for d in "$src_packages"/*/; do
        pkg=$(basename "$d")
        [[ -d "$d.git" ]] || continue
        is_source_only "$pkg" && continue
        pkgs+=("$pkg")
    done
else
    for pkg in "${pkgs[@]}"; do
        is_source_only "$pkg" || continue
        echo "No clean target for $pkg: it is a source-only package" >&2
        exit 1
    done
fi
[[ ${#pkgs[@]} -gt 0 ]] || { echo "Nothing to clean under $src_packages" >&2; exit 1; }

build_dirs=()
for dir in "$buildroot"/build_x86_64*; do
    [[ -f "$dir/build.ninja" ]] && build_dirs+=("$dir")
done
[[ ${#build_dirs[@]} -gt 0 ]] || { echo "No configured build_x86_64* dir under $buildroot" >&2; exit 1; }

rc=0
for pkg in "${pkgs[@]}"; do
    echo ">> Clean $pkg"
    for dir in "${build_dirs[@]}"; do
        ninja -C "$dir" "$pkg-fullclean" || rc=1
        ninja -C "$dir" "$pkg-removeprefix" || rc=1
    done
done

echo ">> Done."
exit $rc
