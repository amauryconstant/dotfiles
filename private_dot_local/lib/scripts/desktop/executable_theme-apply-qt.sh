#!/usr/bin/env sh

# Script: theme-apply-qt.sh
# Purpose: Apply current dotfiles theme to Qt applications via qt5ct
# Requirements: Arch Linux, qt5ct, jaq (aliased to jq)

# Get current theme name
THEME_DIR="$HOME/.config/themes/current"

if [ ! -L "$THEME_DIR" ]; then
    exit 0  # No current theme set, skip silently
fi

THEME_NAME=$(basename "$(readlink "$THEME_DIR")")

# Determine Qt theme and icon theme based on light/dark
case "$THEME_NAME" in
    catppuccin-latte|rose-pine-dawn|gruvbox-light|solarized-light)
        QT_STYLE="Breeze"
        ICON_THEME="breeze"
        ;;
    catppuccin-mocha|rose-pine-moon|gruvbox-dark|solarized-dark)
        QT_STYLE="Breeze"
        ICON_THEME="breeze-dark"
        ;;
    *)
        exit 0  # Unknown theme, skip
        ;;
esac

# qt5ct configuration file
QT5CT_CONF="$HOME/.config/qt5ct/qt5ct.conf"

# Skip if qt5ct not installed or config doesn't exist
if ! command -v qt5ct >/dev/null 2>&1; then
    exit 0
fi

if [ ! -f "$QT5CT_CONF" ]; then
    exit 0
fi

# Update Qt theme using sed (simpler than jaq for INI files)
# Update style setting
sed -i "s/^style=.*/style=$QT_STYLE/" "$QT5CT_CONF"

# Update icon_theme setting
sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$QT5CT_CONF"
