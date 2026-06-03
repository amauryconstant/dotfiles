#!/usr/bin/env sh

# Script: theme-apply-vscode.sh
# Purpose: Apply current dotfiles theme to VSCode
# Requirements: Arch Linux, jaq (aliased to jq)

# Get current theme name
THEME_DIR="$HOME/.config/themes/current"

if [ ! -L "$THEME_DIR" ]; then
    exit 0  # No current theme set, skip silently
fi

THEME_NAME=$(basename "$(readlink "$THEME_DIR")")

# Map dotfiles theme to VSCode theme extension name
case "$THEME_NAME" in
    catppuccin-latte) VSCODE_THEME="Catppuccin Latte" ;;
    catppuccin-mocha) VSCODE_THEME="Catppuccin Mocha" ;;
    rose-pine-dawn)   VSCODE_THEME="Rosé Pine Dawn" ;;
    rose-pine-moon)   VSCODE_THEME="Rosé Pine Moon" ;;
    gruvbox-light)    VSCODE_THEME="Gruvbox Light Hard" ;;
    gruvbox-dark)     VSCODE_THEME="Gruvbox Dark Hard" ;;
    solarized-light)  VSCODE_THEME="Solarized Light" ;;
    solarized-dark)   VSCODE_THEME="Solarized Dark" ;;
    *)                exit 0 ;;  # Unknown theme, skip
esac

# Detect VSCode installation (Code-OSS, Code, or VSCodium)
VSCODE_SETTINGS=""
for vscode_dir in "Code - OSS" "Code" "VSCodium"; do
    candidate="$HOME/.config/$vscode_dir/User/settings.json"
    if [ -f "$candidate" ]; then
        VSCODE_SETTINGS="$candidate"
        break
    fi
done

# Skip if no VSCode installation found
if [ -z "$VSCODE_SETTINGS" ]; then
    exit 0
fi

# Update theme using jaq (aliased to jq)
if command -v jaq >/dev/null 2>&1; then
    jaq --arg theme "$VSCODE_THEME" \
        '.["workbench.colorTheme"] = $theme' \
        "$VSCODE_SETTINGS" > "$VSCODE_SETTINGS.tmp" 2>/dev/null

    # Only replace if jaq succeeded
    if [ $? -eq 0 ] && [ -f "$VSCODE_SETTINGS.tmp" ]; then
        mv "$VSCODE_SETTINGS.tmp" "$VSCODE_SETTINGS"
    else
        rm -f "$VSCODE_SETTINGS.tmp"
    fi
fi
