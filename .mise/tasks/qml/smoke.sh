#!/usr/bin/env bash
#MISE description="Run the rendered Quickshell tree briefly and fail on load errors (needs a Wayland session)"
set -euo pipefail

# 🚨 Some defects only the engine finds: `function escape()` lints and formats
# clean, then the whole file is refused at LOAD ("Illegal method name"). This
# runs the tree the way `quickshell -p` does and greps the log. Manual — it needs
# a live Wayland session, so it is not part of `lint`.
#
# It runs beside the REAL shell, so the scratch copy is patched not to contend
# for anything singular: the notification bus name, the polkit agent, the session
# lock and the menu socket. Nothing here touches ~/.config or the live unit.
[[ -n "${WAYLAND_DISPLAY:-}" ]] || {
	echo "❌ no Wayland session (WAYLAND_DISPLAY unset)" >&2
	exit 1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# shellcheck source=../../lib/render-qml.sh
source "$(git rev-parse --show-toplevel)/.mise/lib/render-qml.sh"
render_qml_tree "$tmp"
cfg="$tmp/dotfiles"

sed -i -E 's/(notificationsOwned|polkitOwned): true/\1: false/; s/(lockOwned): .*/\1: false/' "$cfg/Config.qml"
sed -i 's/quickshell-menu\.sock/quickshell-menu-smoke.sock/' "$cfg/MenuServer.qml"
grep -q 'notificationsOwned: false' "$cfg/Config.qml" || {
	echo "❌ could not neutralise Config ownership flags — Config.qml layout changed" >&2
	exit 1
}

log="$tmp/smoke.log"
# 124 = timeout, the expected exit: a healthy shell runs until it is killed.
QS_DISABLE_FILE_WATCHER=1 timeout "${SMOKE_SECONDS:-8}" quickshell -p "$cfg" >"$log" 2>&1 || [[ $? -eq 124 ]] || true

if grep -nE 'Type .* unavailable|ReferenceError|Illegal method name|TypeError|ERROR|is not a type|Cannot assign' "$log"; then
	echo "❌ the rendered tree reported load/runtime errors (full log above)" >&2
	exit 1
fi
grep -q 'Configuration Loaded' "$log" || {
	echo "❌ the shell never reported 'Configuration Loaded'" >&2
	cat "$log" >&2
	exit 1
}
echo "✅ rendered tree loaded without errors"
