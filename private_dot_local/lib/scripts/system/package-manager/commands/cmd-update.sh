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

        local sync_output
        local sync_status=0

        sync_output=$(cmd_sync --prune 2>&1)
        sync_status=$?

        if [[ $sync_status -ne 0 ]]; then
            ui_error "Sync failed during update (exit code: $sync_status)"
            echo ""

            # Parse error type and provide specific guidance
            if echo "$sync_output" | grep -qi "yaml.*syntax\|parse.*error"; then
                ui_error "  Cause: YAML syntax error in packages.yaml"
                ui_info "  Fix: Validate YAML structure:"
                ui_info "    yq eval . ~/.chezmoidata/packages.yaml"

            elif echo "$sync_output" | grep -qi "package.*not found\|not available"; then
                ui_error "  Cause: Package not found in repositories"
                ui_info "  Fix: Check package availability:"
                ui_info "    package-manager validate --check-packages"

            elif echo "$sync_output" | grep -qi "constraint\|version.*conflict"; then
                ui_error "  Cause: Version constraint violation"
                ui_info "  Fix: Review conflicting constraints:"
                ui_info "    package-manager outdated"

            elif echo "$sync_output" | grep -qi "lock\|already running"; then
                ui_error "  Cause: Sync operation already in progress"
                ui_info "  Fix: Wait or remove stale lock:"
                ui_info "    rm ~/.local/state/package-manager/.sync.lock"

            else
                ui_error "  Run full diagnostics:"
                ui_info "    package-manager validate"
            fi

            return 1
        fi

        ui_success "Sync complete"
        echo ""
    fi

    # Phase 2: Update all Arch/AUR packages
    ui_step "Phase 2/5: Updating Arch/AUR packages..."
    local aur_helper=$(_get_aur_helper)
    if [[ -z "$aur_helper" ]]; then
        ui_error "No AUR helper found. Install paru."
        return 1
    fi

    ui_info "Downloading and installing updates..." >&2
    if ! $aur_helper -Syu --noconfirm; then
        ui_error "Arch/AUR update failed"
        return 1
    fi
    ui_success "Arch/AUR packages updated"
    echo ""

    # Phase 3: Update Flatpak packages
    if [[ "$update_flatpak" == "true" ]] && command -v flatpak >/dev/null 2>&1; then
        ui_step "Phase 3/5: Updating Flatpak packages..."
        if ! _update_flatpaks; then
            ui_warning "Flatpak update failed (non-critical)"
        else
            ui_success "Flatpak packages updated"
        fi
        echo ""
    fi

    # Phase 4: Validation
    ui_step "Phase 4/5: Validating package system..."
    if ! cmd_validate; then
        ui_warning "Validation found issues (non-critical)"
    else
        ui_success "Package system healthy"
    fi
    echo ""

    # Phase 5: Lockfile generation (if enabled)
    if [[ "$AUTO_LOCK" == "true" ]]; then
        ui_step "Phase 5/5: Updating lockfile..."
        cmd_lock --quiet
        ui_success "Lockfile updated"
    fi

    echo ""
    ui_success "System update complete"
    return 0
}
