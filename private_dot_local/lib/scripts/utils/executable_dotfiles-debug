#!/usr/bin/env bash

# Script: dotfiles-debug
# Purpose: Generate comprehensive system debug report
# Requirements: Arch Linux, inxi, gum (optional)

DEBUG_FILE="/tmp/dotfiles-debug-$(date +%Y%m%d-%H%M%S).log"

{
    echo "=== System Information ==="
    inxi -Farz

    echo -e "\n=== Kernel Messages ==="
    dmesg | tail -100

    echo -e "\n=== Journal Errors (Boot) ==="
    journalctl -b -p 4..1 --no-pager

    echo -e "\n=== Package List ==="
    pacman -Q

    echo -e "\n=== Flatpak Packages ==="
    flatpak list --app 2>/dev/null || echo "No Flatpak packages installed"

    echo -e "\n=== Chezmoi Status ==="
    chezmoi status 2>/dev/null || echo "Unable to get chezmoi status"

    echo -e "\n=== Theme Information ==="
    if [ -f "$HOME/.config/themes/current/theme.yaml" ]; then
        cat "$HOME/.config/themes/current/theme.yaml"
    else
        echo "No theme information available"
    fi

    echo -e "\n=== Active Services ==="
    systemctl --user list-units --state=running --no-pager

    echo -e "\n=== Hyprland Information ==="
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Version:"
        hyprctl version
        echo -e "\nMonitors:"
        hyprctl monitors
    else
        echo "Hyprland not running or not installed"
    fi

} > "$DEBUG_FILE"

echo "Debug log saved to: $DEBUG_FILE"

# Optional upload with confirmation
if command -v gum >/dev/null 2>&1; then
    if gum confirm "Upload to 0x0.st?"; then
        echo "Uploading..."
        url=$(curl -F "file=@$DEBUG_FILE" https://0x0.st 2>/dev/null)

        if [ -n "$url" ]; then
            echo "Uploaded: $url"
            echo "$url" | wl-copy 2>/dev/null && echo "URL copied to clipboard"
            notify-send "Debug Log" "URL copied to clipboard: $url" 2>/dev/null || true
        else
            echo "Upload failed"
        fi
    fi
else
    echo ""
    echo "Tip: Install 'gum' for interactive upload option"
fi
