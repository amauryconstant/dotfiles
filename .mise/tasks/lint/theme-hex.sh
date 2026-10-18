#!/usr/bin/env bash
#MISE description="Reject malformed Hyprland colour literals (the silent 10-digit truncation)"
#MISE quiet=true
set -euo pipefail
shopt -s lastpipe

# Hyprland takes 8 hex digits: rgba(rrggbbaa), or ARGB 0xaarrggbb. A 10-digit
# 0xff<rrggbb><aa> is SILENTLY truncated to its last 8, shifting every channel —
# no parse error, just wrong colours (.claude/rules/hyprland-lua.md → "Color
# format"). Rose-pine dawn/moon shipped exactly that. Literals only: an
# expression like "rgba(" .. hex .. "ff)" has no digits to count.
paths=(
	'private_dot_config/themes/*/hyprland.conf'
	'private_dot_config/themes/*/hyprland.lua'
	'private_dot_config/hypr'
	'private_dot_config/hyprdynamicmonitors'
)
status=0

report() {
	while IFS= read -r hit; do
		echo "❌ $hit — $1" >&2
		status=1
	done
}

git grep -nE '0x[0-9a-fA-F]{9,}' -- "${paths[@]}" | report '0x literal wider than 8 digits is truncated to the last 8' || true
git grep -nE 'rgba\([0-9a-fA-F]+\)' -- "${paths[@]}" | grep -vE 'rgba\([0-9a-fA-F]{8}\)' | report 'rgba() needs exactly 8 hex digits' || true
git grep -nE 'rgb\([0-9a-fA-F]+\)' -- "${paths[@]}" | grep -vE 'rgb\([0-9a-fA-F]{6}\)' | report 'rgb() needs exactly 6 hex digits' || true

exit "$status"
