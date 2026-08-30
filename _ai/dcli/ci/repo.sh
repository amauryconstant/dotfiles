#!/usr/bin/env bash
# Rebuild the pacman repo database in <repo-dir>, keeping the newest
# $KEEP_BUILDS packages and removing older ones.
set -euo pipefail

repo_dir="${1:?usage: repo.sh <repo-dir>}"
keep="${KEEP_BUILDS:-4}"

cd "$repo_dir"
shopt -s nullglob
mapfile -t pkgs < <(ls -1t dcli-[0-9]*.pkg.tar.zst)

if ((${#pkgs[@]} == 0)); then
    echo "repo.sh: no dcli packages found in $repo_dir" >&2
    exit 1
fi

if ((${#pkgs[@]} > keep)); then
    echo "Pruning $(( ${#pkgs[@]} - keep )) old build(s):"
    printf '  %s\n' "${pkgs[@]:keep}"
    rm -f "${pkgs[@]:keep}"
fi

rm -f dcli.db dcli.db.tar.gz dcli.files dcli.files.tar.gz
repo-add dcli.db.tar.gz dcli-[0-9]*.pkg.tar.zst

echo 'Repo database rebuilt with:'
tar -tf dcli.db.tar.gz | grep '/desc$'