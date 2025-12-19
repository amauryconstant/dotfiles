#!/usr/bin/env bash

# Script: cmd-install.sh
# Purpose: Install a single package
# Requirements: paru, yq

cmd_install() {
    if [[ $# -eq 0 ]]; then
        ui_error "Usage: package-manager install <package>"
        return 1
    fi

    local package="$1"

    _install_package "$package" "manual"
}
