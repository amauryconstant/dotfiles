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

# Map dotfiles theme to spicetify theme
# Note: Assumes spicetify themes are already installed
case "$THEME_NAME" in
    catppuccin-latte|catppuccin-mocha)
        spicetify config current_theme catppuccin >/dev/null 2>&1
        case "$THEME_NAME" in
            catppuccin-latte) spicetify config color_scheme latte >/dev/null 2>&1 ;;
            catppuccin-mocha) spicetify config color_scheme mocha >/dev/null 2>&1 ;;
        esac
        ;;
    rose-pine-dawn|rose-pine-moon)
        spicetify config current_theme Rosé-Pine >/dev/null 2>&1
        case "$THEME_NAME" in
            rose-pine-dawn) spicetify config color_scheme dawn >/dev/null 2>&1 ;;
            rose-pine-moon) spicetify config color_scheme moon >/dev/null 2>&1 ;;
        esac
        ;;
    gruvbox-light|gruvbox-dark)
        spicetify config current_theme Gruvbox >/dev/null 2>&1
        case "$THEME_NAME" in
            gruvbox-light) spicetify config color_scheme light >/dev/null 2>&1 ;;
            gruvbox-dark)  spicetify config color_scheme dark >/dev/null 2>&1 ;;
        esac
        ;;
    solarized-light|solarized-dark)
        spicetify config current_theme Solarized >/dev/null 2>&1
        case "$THEME_NAME" in
            solarized-light) spicetify config color_scheme light >/dev/null 2>&1 ;;
            solarized-dark)  spicetify config color_scheme dark >/dev/null 2>&1 ;;
        esac
        ;;
    *)
        exit 0  # Unknown theme, skip
        ;;
esac

# Apply theme
spicetify apply >/dev/null 2>&1
