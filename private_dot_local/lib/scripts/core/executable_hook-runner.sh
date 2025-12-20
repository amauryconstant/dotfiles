#!/usr/bin/env sh

# Script: hook-runner.sh
# Purpose: Execute user hooks without modifying core scripts
# Requirements: Arch Linux

# Usage: hook-runner.sh <hook-name> [args...]
# Example: hook-runner.sh theme-change "catppuccin-latte"

HOOK_NAME="$1"
shift

HOOKS_DIR="$HOME/.config/dotfiles/hooks"
HOOK_PATH="$HOOKS_DIR/$HOOK_NAME"

# Silent execution - hooks are optional
# Errors are suppressed to avoid breaking calling scripts
if [ -x "$HOOK_PATH" ]; then
    "$HOOK_PATH" "$@" 2>/dev/null || true
fi
