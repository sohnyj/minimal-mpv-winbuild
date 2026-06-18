#!/bin/bash
# Refresh git-based package sources and invalidate stamps by running `ninja
# update` in every configured build_x86_64* dir under buildroot. Standalone
# helper for manually syncing sources between builds.
#
# Usage: update-repo.sh [buildroot]
#   buildroot  location of the build_x86_64* dirs
#              (default: the repository root)
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

gitdir=$(cd "$(dirname "$(realpath "$0")")/.." && pwd)

buildroot=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage 0 ;;
        -*)        echo "unknown option: $1" >&2; usage 1 ;;
        *)         buildroot="$1"; shift ;;
    esac
done
[[ -n "$buildroot" ]] || buildroot="$gitdir"
buildroot=$(cd "$buildroot" && pwd)

shopt -s nullglob
rc=0
found=0
for dir in "$buildroot"/build_x86_64*; do
    [[ -f "$dir/build.ninja" ]] || continue
    found=1
    echo ">> Updating $(basename "$dir")"
    ninja -C "$dir" update || rc=1
done

if [[ $found -eq 0 ]]; then
    echo "No configured build_x86_64* dir under $buildroot (configure a build first)" >&2
    exit 1
fi
exit $rc
