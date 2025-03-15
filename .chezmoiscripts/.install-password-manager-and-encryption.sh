#!/bin/sh

if (command -v rbw >/dev/null 2>&1 && command -v rage >/dev/null 2>&1); then
    exit
fi

case "$(uname -s)" in
Linux)
    # Install rbw and rage through pacman to be able to use encryption from the vault
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm --needed rbw rage-encryption
    fi
    
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac
