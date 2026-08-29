#!/usr/bin/env bash
# Usage: scripts/check-theme-files.sh <theme-name> [reference-theme]
#
# Diffs a theme dir's file list against a reference theme dir, rather than a
# hardcoded list — private_dot_config/themes/CLAUDE.md's documented file set
# has already drifted from reality once (zellij.kdl and wallpapers/README.md
# exist in every theme dir but aren't in the doc's list), so a live reference
# theme is the only trustworthy source of truth.
set -euo pipefail

theme="${1:?usage: check-theme-files.sh <theme-name> [reference-theme]}"
reference="${2:-rose-pine-moon}"

theme_dir="private_dot_config/themes/$theme"
reference_dir="private_dot_config/themes/$reference"

if [ ! -d "$theme_dir" ]; then
	echo "❌ $theme_dir does not exist" >&2
	exit 1
fi
if [ ! -d "$reference_dir" ]; then
	echo "❌ reference theme $reference_dir does not exist" >&2
	exit 1
fi

expected=$(cd "$reference_dir" && find . -type f | sort)
actual=$(cd "$theme_dir" && find . -type f | sort)

missing=$(comm -23 <(echo "$expected") <(echo "$actual"))
extra=$(comm -13 <(echo "$expected") <(echo "$actual"))

status=0
if [ -n "$missing" ]; then
	echo "❌ Missing in $theme_dir (present in $reference_dir):"
	echo "$missing" | sed 's/^/   /'
	status=1
fi
if [ -n "$extra" ]; then
	echo "⚠️  Extra in $theme_dir (not in $reference_dir — confirm intentional):"
	echo "$extra" | sed 's/^/   /'
fi
if [ -z "$missing" ] && [ -z "$extra" ]; then
	echo "✅ $theme_dir matches $reference_dir's file set exactly"
fi

exit $status
