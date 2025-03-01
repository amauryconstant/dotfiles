#!/bin/sh

if (command -v rbw >/dev/null 2>&1 && command -v rage >/dev/null 2>&1); then
    exit
fi

case "$(uname -s)" in
Linux)
    # Install rbw through pacman
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed rbw rage-encryption
    fi
    
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac
