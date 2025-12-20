#!/usr/bin/env sh

# Darkman transition script: Switch to light theme variant at sunrise
# Triggered automatically by darkman daemon

THEMES_DIR="$HOME/.config/themes"
CURRENT_LINK="$THEMES_DIR/current"

# Get current theme name
if [ -L "$CURRENT_LINK" ]; then
    CURRENT_THEME=$(readlink "$CURRENT_LINK" | xargs basename)

    # Map dark variants to their light counterparts
    case "$CURRENT_THEME" in
        *-dark)
            # Standard naming: gruvbox-dark, solarized-dark
            LIGHT_THEME=$(echo "$CURRENT_THEME" | sed 's/-dark$/-light/')
            ;;
        catppuccin-mocha)
            LIGHT_THEME="catppuccin-latte"
            ;;
        rose-pine-moon)
            LIGHT_THEME="rose-pine-dawn"
            ;;
        *)
            # Already light or unknown, no change needed
            exit 0
            ;;
    esac

    # Only switch if we're not already on the light variant
    if [ "$CURRENT_THEME" != "$LIGHT_THEME" ]; then
        if [ -d "$THEMES_DIR/$LIGHT_THEME" ]; then
            ~/.local/lib/scripts/desktop/theme-switcher.sh switch "$LIGHT_THEME"

            # Call user hook
            if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                "$HOME/.local/lib/scripts/core/hook-runner.sh" dark-mode-change "light" 2>/dev/null || true
            fi
        fi
    fi
fi
