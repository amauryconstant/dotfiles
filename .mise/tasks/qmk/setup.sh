#!/usr/bin/env bash
#MISE description="Clone mainline QMK at the pinned commit (idempotent) and fetch its submodules"
set -euo pipefail

# shellcheck source=../../lib/qmk-env.sh
source "$(git rev-parse --show-toplevel)/.mise/lib/qmk-env.sh"

command -v qmk >/dev/null || {
	echo "❌ qmk not installed (packages.yaml → keyboard_firmware; install it first)" >&2
	exit 1
}

if [[ ! -d "$QMK_HOME/.git" ]]; then
	mkdir -p "$(dirname "$QMK_HOME")"
	git clone "$QMK_FIRMWARE_URL" "$QMK_HOME"
fi

if [[ "$(git -C "$QMK_HOME" rev-parse HEAD 2>/dev/null)" != "$QMK_FIRMWARE_REF" ]]; then
	git -C "$QMK_HOME" fetch --tags origin
	git -C "$QMK_HOME" checkout --detach "$QMK_FIRMWARE_REF"
fi

# A tag can be force-moved upstream; the SHA is the pin, the tag is only its name.
tag_sha=$(git -C "$QMK_HOME" rev-parse --verify --quiet "refs/tags/$QMK_FIRMWARE_TAG^{commit}" || true)
if [[ -n "$tag_sha" && "$tag_sha" != "$QMK_FIRMWARE_REF" ]]; then
	echo "❌ tag $QMK_FIRMWARE_TAG now points at $tag_sha, not the pinned $QMK_FIRMWARE_REF" >&2
	echo "   upstream moved the tag: review before touching the pin" >&2
	exit 1
fi

qmk git-submodule
echo "✅ QMK $(git -C "$QMK_HOME" describe --tags --always) at $QMK_HOME"
