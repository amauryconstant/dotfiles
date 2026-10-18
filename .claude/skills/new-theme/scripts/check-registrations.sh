#!/usr/bin/env bash
# Usage: scripts/check-registrations.sh <theme-name>
#
# theme-switcher discovers themes by globbing private_dot_config/themes/*, so
# it needs no registration. But several OTHER scripts hardcode exact theme
# names in case arms and silently no-op (or fall back to a default) for an
# unregistered theme. This greps each for the new theme name.
#
# theme-switcher's theme_variant() is the one that matters most: GTK, Qt and
# Claude Code all switch on its dark/light/other answer, and an unrecognised
# theme answers "other".
set -euo pipefail

theme="${1:?usage: check-registrations.sh <theme-name>}"

files=(
	"private_dot_local/lib/scripts/desktop/executable_theme-switcher.tmpl"
	"private_dot_local/lib/scripts/desktop/executable_theme-apply-spotify"
	"private_dot_config/nvim/lua/dotfiles_theme.lua"
	"private_dot_local/share/dark-mode.d/executable_01-switch-theme.sh"
	"private_dot_local/share/light-mode.d/executable_01-switch-theme.sh"
	".chezmoiscripts/run_once_before_007_setup_default_theme.sh.tmpl"
)

status=0
for f in "${files[@]}"; do
	if [ ! -f "$f" ]; then
		echo "⚠️  $f not found (skipped — may have moved, check manually)"
		continue
	fi
	if grep -q "$theme" "$f"; then
		echo "✅ $f already references $theme"
	else
		echo "❌ $f has no case arm for $theme — add one"
		status=1
	fi
done

echo ""
echo "Not checked here (name-agnostic, no registration needed):"
echo "  theme-apply-gtk/-qt/-claude-code (switch on theme-switcher variant, checked above),"
echo "  theme-apply-opencode (light/dark via *latte*|*light*|*dawn* glob, not exact-name),"
echo "  theme-apply-firefox, theme-apply-neovim (file-presence/symlink based, no theme-name branching)"

exit $status
