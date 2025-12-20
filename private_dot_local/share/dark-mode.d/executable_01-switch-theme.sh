#!/usr/bin/env sh

# Darkman transition script: Switch to dark theme variant at sunset
# Triggered automatically by darkman daemon

THEMES_DIR="$HOME/.config/themes"
CURRENT_LINK="$THEMES_DIR/current"

# Get current theme name
if [ -L "$CURRENT_LINK" ]; then
    CURRENT_THEME=$(readlink "$CURRENT_LINK" | xargs basename)

    # Map light variants to their dark counterparts
    case "$CURRENT_THEME" in
        *-light)
            # Standard naming: gruvbox-light, solarized-light
            DARK_THEME=$(echo "$CURRENT_THEME" | sed 's/-light$/-dark/')
            ;;
        catppuccin-latte)
            DARK_THEME="catppuccin-mocha"
            ;;
        rose-pine-dawn)
            DARK_THEME="rose-pine-moon"
            ;;
        *)
            # Already dark or unknown, no change needed
            exit 0
            ;;
    esac

    # Only switch if we're not already on the dark variant
    if [ "$CURRENT_THEME" != "$DARK_THEME" ]; then
        if [ -d "$THEMES_DIR/$DARK_THEME" ]; then
            ~/.local/lib/scripts/desktop/theme-switcher.sh switch "$DARK_THEME"

            # Call user hook
            if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                "$HOME/.local/lib/scripts/core/hook-runner.sh" dark-mode-change "dark" 2>/dev/null || true
            fi
        fi
    fi
fi
