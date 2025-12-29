#!/usr/bin/env bash

# Script: cmd-update.sh
# Purpose: Update all system packages (hybrid mode)
# Requirements: paru, flatpak, yq

cmd_update() {
    local sync_first=true
    local update_flatpak=true

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-sync)
                sync_first=false
                shift
                ;;
            --no-flatpak)
                update_flatpak=false
                shift
                ;;
            *)
                ui_error "Unknown flag: $1"
                ui_info "Usage: package-manager update [--no-sync] [--no-flatpak]"
                return 1
                ;;
        esac
    done

    ui_title "$ICON_PACKAGE System Package Update"

    # Phase 1: Sync to packages.yaml
    if [[ "$sync_first" == "true" ]]; then
        ui_step "Phase 1/5: Syncing to packages.yaml..."
        ui_spacer

        if ! cmd_sync --prune; then
            ui_error "Sync failed during update"
            ui_info "Run 'package-manager validate' for diagnostics"
            return 1
        fi

        ui_spacer
        ui_success "Sync complete"
        ui_spacer
    fi

    # Phase 2: Update all Arch/AUR packages
    ui_step "Phase 2/5: Updating Arch/AUR packages..."
    local aur_helper=$(_get_aur_helper)
    if [[ -z "$aur_helper" ]]; then
        ui_error "No AUR helper found. Install paru."
        return 1
    fi

    # Direct call (paru needs TTY for sudo prompts and progress display)
    if ! $aur_helper -Syu --noconfirm; then
        ui_error "Arch/AUR update failed"
        return 1
    fi
    ui_success "Arch/AUR packages updated"
    ui_spacer

    # Phase 3: Update Flatpak packages
    if [[ "$update_flatpak" == "true" ]] && command -v flatpak >/dev/null 2>&1; then
        ui_spacer
        ui_step "Phase 3/5: Updating Flatpak packages..."
        ui_spacer
        if ! _update_flatpaks; then
            ui_warning "Flatpak update failed (non-critical)" --before 1
        fi
        ui_spacer
    fi

    # Phase 4: Validation
    ui_spacer
    ui_step "Phase 4/5: System Validation"
    ui_spacer
    if ! cmd_validate; then
        ui_warning "Validation found issues (non-critical)" --before 1
    fi
    ui_spacer

    # Phase 5: Lockfile generation (if enabled)
    if [[ "$AUTO_LOCK" == "true" ]]; then
        ui_step "Phase 5/5: Updating lockfile..."
        cmd_lock --quiet
        ui_success "Lockfile updated"
    fi

    ui_spacer
    ui_success "System update complete"
    return 0
}
