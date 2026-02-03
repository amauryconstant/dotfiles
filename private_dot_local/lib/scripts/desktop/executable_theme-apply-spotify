#!/usr/bin/env sh

# Script: theme-apply-spotify.sh
# Purpose: Apply current dotfiles theme to Spotify via spicetify
# Requirements: Arch Linux, spicetify-cli (optional)

# Check if spicetify is installed
if ! command -v spicetify >/dev/null 2>&1; then
    exit 0  # Spicetify not installed, skip silently
fi

# Get current theme name
THEME_DIR="$HOME/.config/themes/current"

if [ ! -L "$THEME_DIR" ]; then
    exit 0  # No current theme set, skip silently
fi

THEME_NAME=$(basename "$(readlink "$THEME_DIR")")

# Map dotfiles theme to spicetify dotfiles-themes
# Note: All themes use custom dotfiles-themes with matching color schemes
case "$THEME_NAME" in
    catppuccin-latte|catppuccin-mocha|rose-pine-dawn|rose-pine-moon|gruvbox-light|gruvbox-dark|solarized-light|solarized-dark)
        spicetify config current_theme dotfiles-themes >/dev/null 2>&1
        spicetify config color_scheme "$THEME_NAME" >/dev/null 2>&1
        ;;
    *)
        exit 0  # Unknown theme, skip
        ;;
esac

# Apply theme
spicetify apply >/dev/null 2>&1
