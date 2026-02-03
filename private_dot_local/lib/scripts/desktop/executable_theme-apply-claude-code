#!/usr/bin/env sh

# Script: theme-apply-claude-code.sh
# Purpose: Apply current dotfiles theme to claude-code CLI
# Requirements: Arch Linux, jaq (aliased to jq)

# Get current theme name
THEME_DIR="$HOME/.config/themes/current"

if [ ! -L "$THEME_DIR" ]; then
    exit 0  # No current theme set, skip silently
fi

THEME_NAME=$(basename "$(readlink "$THEME_DIR")")

# Map dotfiles theme to claude-code theme (light/dark)
case "$THEME_NAME" in
    catppuccin-latte|rose-pine-dawn|gruvbox-light|solarized-light)
        CLAUDE_THEME="light"
        ;;
    catppuccin-mocha|rose-pine-moon|gruvbox-dark|solarized-dark)
        CLAUDE_THEME="dark"
        ;;
    *)
        exit 0  # Unknown theme, skip
        ;;
esac

# Detect claude-code config
CLAUDE_CONFIG="$HOME/.claude.json"
if [ ! -f "$CLAUDE_CONFIG" ]; then
    exit 0  # claude-code not installed, skip silently
fi

# Update claude.json to set theme
if command -v jaq >/dev/null 2>&1; then
    jaq --arg theme "$CLAUDE_THEME" \
        '.theme = $theme' \
        "$CLAUDE_CONFIG" > "$CLAUDE_CONFIG.tmp" 2>/dev/null

    # Only replace if jaq succeeded
    if [ $? -eq 0 ] && [ -f "$CLAUDE_CONFIG.tmp" ]; then
        mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"
    else
        rm -f "$CLAUDE_CONFIG.tmp"
    fi
fi
