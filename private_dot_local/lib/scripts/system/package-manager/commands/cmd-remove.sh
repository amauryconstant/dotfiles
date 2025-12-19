#!/usr/bin/env bash

# Script: cmd-remove.sh
# Purpose: Remove a package
# Requirements: paru, yq

cmd_remove() {
    if [[ $# -eq 0 ]]; then
        ui_error "Usage: package-manager remove <package>"
        return 1
    fi

    local package="$1"

    _remove_package "$package"
}
