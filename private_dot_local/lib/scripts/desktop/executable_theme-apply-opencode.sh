#!/usr/bin/env sh

# Script: theme-apply-opencode.sh
# Purpose: Apply current dotfiles theme to opencode
# Requirements: Arch Linux, jaq (aliased to jq)

# Get current theme name
THEME_DIR="$HOME/.config/themes/current"

if [ ! -L "$THEME_DIR" ]; then
    exit 0  # No current theme set, skip silently
fi

# Verify opencode theme file exists
OPENCODE_THEME="$THEME_DIR/opencode.json"
if [ ! -f "$OPENCODE_THEME" ]; then
    exit 0  # Theme file missing, skip silently
fi

# Detect opencode config
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.jsonc"
if [ ! -f "$OPENCODE_CONFIG" ]; then
    exit 0  # opencode not installed, skip silently
fi

# Create themes directory if missing
mkdir -p "$HOME/.config/opencode/themes"

# Symlink current theme
rm -f "$HOME/.config/opencode/themes/current.json"
ln -s "$OPENCODE_THEME" "$HOME/.config/opencode/themes/current.json"

# Update opencode.jsonc to use "current" theme
if command -v jaq >/dev/null 2>&1; then
    jaq '.theme = "current"' \
        "$OPENCODE_CONFIG" > "$OPENCODE_CONFIG.tmp" 2>/dev/null

    # Only replace if jaq succeeded
    if [ $? -eq 0 ] && [ -f "$OPENCODE_CONFIG.tmp" ]; then
        mv "$OPENCODE_CONFIG.tmp" "$OPENCODE_CONFIG"
    else
        rm -f "$OPENCODE_CONFIG.tmp"
    fi
fi
