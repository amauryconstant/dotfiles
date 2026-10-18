#!/usr/bin/env bash
#MISE description="Run one Lua dispatcher in a nested Hyprland and print the reply (needs a Wayland session)"
set -euo pipefail

# Usage: mise run hypr:probe -- 'hl.dsp.exec_cmd("true")'
#
# lint:hypr-lua and stylua prove the tree PARSES; the stub types every dispatcher
# as fun(...), so a wrong argument passes both. A nested Hyprland nests as a
# Wayland client inside the running session, so it cannot touch the live one.
# Procedure and rationale: .claude/rules/hyprland-lua.md → "Proving a dispatcher's
# arguments: a nested Hyprland".
#
# 🚨 Read the reply, not just the exit code: a bad call prints `error: …` and exits
# 7, but a call that succeeds WITHOUT DOING ANYTHING prints `info: …` and exits 0.
# Confirm the effect with `HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl clients -j`.
expr=${1:?usage: hypr:probe -- '<hl.dsp… expression>'}
[[ -n "${WAYLAND_DISPLAY:-}" ]] || {
	echo "❌ no Wayland session (WAYLAND_DISPLAY unset)" >&2
	exit 1
}

hyprdir="${XDG_RUNTIME_DIR:?}/hypr"
tmp=$(mktemp -d)
pid=
sig=
cleanup() {
	if [[ -n "$pid" ]]; then
		kill "$pid" 2>/dev/null || true
		wait "$pid" 2>/dev/null || true
	fi
	# A killed Hyprland leaves its instance dir behind; it is ours, found as new.
	[[ -z "$sig" ]] || rm -r "${hyprdir:?}/${sig:?}" 2>/dev/null || true
	rm -rf "$tmp"
}
trap cleanup EXIT

# Minimal entry point: hl.config({}) selects the Lua provider; the real tree would
# drag in plugins, monitors and autostart.
printf 'hl.config({})\npackage.path = os.getenv("HOME") .. "/.config/hypr/?.lua;" .. package.path\n' >"$tmp/hyprland.lua"

mapfile -t before < <(ls "$hyprdir" 2>/dev/null || true)
Hyprland -c "$tmp/hyprland.lua" >"$tmp/hyprland.log" 2>&1 &
pid=$!

for _ in $(seq 1 50); do
	while IFS= read -r d; do
		[[ " ${before[*]-} " == *" $d "* ]] || sig=$d
	done < <(ls "$hyprdir" 2>/dev/null || true)
	if [[ -n "$sig" ]] && HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -j status >"$tmp/status.json" 2>/dev/null; then
		break
	fi
	sleep 0.2
done
[[ -n "$sig" && -s "$tmp/status.json" ]] || {
	echo "❌ nested Hyprland did not come up" >&2
	cat "$tmp/hyprland.log" >&2
	exit 1
}
echo "nested instance: $sig ($(jaq -r '.configProvider // "?"' "$tmp/status.json"))"

set +e
reply=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl dispatch "$expr" 2>&1)
rc=$?
set -e
echo "exit $rc"
echo "reply: $reply"
exit "$rc"
