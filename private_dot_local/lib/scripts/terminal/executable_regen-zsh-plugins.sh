#!/usr/bin/env bash

# Script: regen-zsh-plugins
# Purpose: Regenerate zsh plugins bundle
# Requirements: Arch Linux, zsh-antidote

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
PLUGINS_TXT="$ZDOTDIR/.zsh_plugins.txt"
PLUGINS_ZSH="$ZDOTDIR/.zsh_plugins.zsh"
ANTIDOTE_ZSH="/usr/share/zsh-antidote/antidote.zsh"

# Check if antidote is installed
if [ ! -f "$ANTIDOTE_ZSH" ]; then
    echo "❌ zsh-antidote not installed"
    echo "   Run: paru -S zsh-antidote"
    exit 1
fi

# Check if plugins.txt exists
if [ ! -f "$PLUGINS_TXT" ]; then
    echo "❌ Plugin list not found: $PLUGINS_TXT"
    exit 1
fi

# Remove old bundle
if [ -f "$PLUGINS_ZSH" ]; then
    echo "→ Removing old plugin bundle..."
    rm -f "$PLUGINS_ZSH"
fi

# Generate new bundle using zsh to access antidote function
echo "→ Regenerating zsh plugins bundle..."
zsh -c "source '$ANTIDOTE_ZSH' && antidote bundle <'$PLUGINS_TXT' >'$PLUGINS_ZSH'" 2>/dev/null

if [ -f "$PLUGINS_ZSH" ] && [ -s "$PLUGINS_ZSH" ]; then
    SOURCE_COUNT=$(grep -c "^source \"" "$PLUGINS_ZSH" 2>/dev/null || echo "0")
    echo "✓ Plugins regenerated successfully"
    echo "  Bundle: $PLUGINS_ZSH"
    echo "  Source count: $SOURCE_COUNT plugins"
    echo ""
    echo "Reload your shell or run: exec zsh"
else
    echo "❌ Failed to generate plugins"
    echo "   Check internet connection and try again"
    exit 1
fi
