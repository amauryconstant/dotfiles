#!/bin/sh

if (command -v rbw >/dev/null 2>&1 && command -v rage >/dev/null 2>&1); then
    exit
fi

case "$(uname -s)" in
Linux)
    echo "🚀 Installing password manager and encryption tools..."
    
    # Install rbw and rage through pacman to be able to use encryption from the vault
    if command -v pacman >/dev/null 2>&1; then
        echo "📋 Installing rbw and rage-encryption..."
        sudo pacman -S --noconfirm --needed rbw rage-encryption
        echo "✅ [SUCCESS] Password manager and encryption tools installed"
    fi
    
    ;;
*)
    echo "❌ [ERROR] This script is only supported on Linux systems"
    echo "❌ [ERROR] Required: Linux (any distribution)"
    echo "❌ [ERROR] Detected: $(uname -s)"
    echo "❌ [ERROR] Script: $(basename "$0")"
    exit 1
    ;;
esac
