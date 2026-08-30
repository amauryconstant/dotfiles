#!/usr/bin/env bash
# Verify the package published in the pacman repo still links against the
# CURRENT Arch repositories. Run inside a fully updated Arch container.
# Exits non-zero (and prints the broken binaries) if any ELF in the package
# has an unresolvable library.
set -euo pipefail

server="${1:?usage: smoke.sh <repo-server-url>}"   # e.g. https://theblackdon.gitlab.io/dcli/x86_64
work="$(mktemp -d)"
cd "$work"

pacman -S --noconfirm --needed libarchive curl >/dev/null

echo ">> Fetching repo database from $server"
curl -sfL "$server/dcli.db.tar.gz" -o db.tar.gz
entry="$(bsdtar -tf db.tar.gz | grep '/desc$' | grep -v -- '-debug-' | sort -V | tail -1)"
pkg="${entry%/desc}-x86_64.pkg.tar.zst"
echo ">> Latest published package: $pkg"

curl -sfL "$server/$pkg" -o pkg.tar.zst
mkdir root
bsdtar -xf pkg.tar.zst -C root

# Install the package's dependencies that exist in the Arch repos.
mapfile -t deps < <(bsdtar -xOf pkg.tar.zst .PKGINFO | sed -n 's/^depend = //p' | sed 's/[<>=].*$//' | sort -u)
todo=()
for d in "${deps[@]}"; do
    if pacman -Si "$d" &>/dev/null; then
        todo+=("$d")
    else
        echo ">> skipping (not in Arch repos): $d"
    fi
done
if ((${#todo[@]})); then
    pacman -S --noconfirm --needed "${todo[@]}"
fi

# Link-check every shipped ELF, preferring the package's own bundled libs.
export LD_LIBRARY_PATH="$work/root/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fail=0
while IFS= read -r f; do
    out="$(ldd "$f" 2>/dev/null || true)"
    if grep -q 'not found' <<<"$out"; then
        echo "BROKEN: ${f#"$work"/root}"
        grep 'not found' <<<"$out" | sed 's/^/    /'
        fail=1
    fi
done < <(find root/usr -type f \( -name '*.so*' -o -perm -u+x \))

if ((fail)); then
    echo '>> SMOKE TEST FAILED: binary no longer links against current Arch.'
    echo '>> Trigger a rebuild: GitLab -> Build -> Pipelines -> Run pipeline.'
    exit 1
fi
echo '>> SMOKE TEST PASSED'