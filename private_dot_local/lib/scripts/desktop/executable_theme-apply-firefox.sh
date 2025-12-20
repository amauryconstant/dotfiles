#!/usr/bin/env sh

# Script: theme-apply-firefox.sh
# Purpose: Apply current dotfiles theme to Firefox via userChrome.css
# Requirements: Arch Linux, Firefox
# Note: Requires toolkit.legacyUserProfileCustomizations.stylesheets = true in about:config

# Get current theme directory
THEME_DIR="$HOME/.config/themes/current"

if [ ! -L "$THEME_DIR" ]; then
    exit 0  # No current theme set, skip silently
fi

# Check if Firefox userChrome.css exists in theme
USERCHROME_SOURCE="$THEME_DIR/firefox-userChrome.css"

if [ ! -f "$USERCHROME_SOURCE" ]; then
    exit 0  # Theme doesn't have Firefox support, skip
fi

# Find Firefox profile directory
FIREFOX_DIR="$HOME/.mozilla/firefox"

if [ ! -d "$FIREFOX_DIR" ]; then
    exit 0  # Firefox not installed, skip
fi

# Find default-release profile (most common)
FIREFOX_PROFILE=$(find "$FIREFOX_DIR" -maxdepth 1 -type d -name "*.default-release" | head -1)

# Fallback to any .default profile
if [ -z "$FIREFOX_PROFILE" ]; then
    FIREFOX_PROFILE=$(find "$FIREFOX_DIR" -maxdepth 1 -type d -name "*.default" | head -1)
fi

if [ -z "$FIREFOX_PROFILE" ] || [ ! -d "$FIREFOX_PROFILE" ]; then
    exit 0  # No profile found, skip
fi

# Create chrome directory if needed
CHROME_DIR="$FIREFOX_PROFILE/chrome"
mkdir -p "$CHROME_DIR"

# Symlink userChrome.css
USERCHROME_TARGET="$CHROME_DIR/userChrome.css"

# Remove existing file/symlink
rm -f "$USERCHROME_TARGET"

# Create symlink
ln -sf "$USERCHROME_SOURCE" "$USERCHROME_TARGET"
