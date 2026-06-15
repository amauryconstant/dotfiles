#!/usr/bin/env bash

# Script: cmd-approve.sh
# Purpose: Approve AUR PKGBUILDs for the supply-chain tripwire
# Requirements: pacman, paru, yq (via operations/pkgbuild-tripwire.sh)

# Review + record a single AUR package's PKGBUILD.
_approve_one() {
    local name="$1"

    if ! _pkg_is_aur "$name"; then
        ui_warning "'$name' is not an AUR package — skipping"
        return 0
    fi

    local current_text
    current_text=$(_tripwire_fetch "$name")
    if [[ -z "$current_text" ]]; then
        ui_error "Could not fetch PKGBUILD for '$name'"
        return 1
    fi

    ui_title "Review PKGBUILD: $name"
    if [[ -f "$TRIPWIRE_SNAP_DIR/$name.PKGBUILD" ]]; then
        ui_info "Diff since last approval (- approved / + current):"
        diff -u "$TRIPWIRE_SNAP_DIR/$name.PKGBUILD" <(printf '%s\n' "$current_text") || true
    else
        ui_info "New package — full PKGBUILD:"
        printf '%s\n' "$current_text"
    fi
    ui_spacer

    if ui_confirm "Approve this PKGBUILD for '$name'?"; then
        if _tripwire_record "$name" "$current_text"; then
            ui_success "Approved $name"
        else
            ui_error "Failed to record approval for $name"
            return 1
        fi
    else
        ui_info "Skipped $name"
    fi
}

cmd_approve() {
    local seed=false all=false
    local -a names=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --seed)
                seed=true
                shift
                ;;
            --all)
                all=true
                shift
                ;;
            -*)
                ui_error "Unknown flag: $1"
                ui_info "Usage: package-manager approve [<package>...] [--all] [--seed]"
                return 1
                ;;
            *)
                names+=("$1")
                shift
                ;;
        esac
    done

    # Seed: trust-on-first-use bootstrap of all installed AUR packages (no prompt)
    if [[ "$seed" == "true" ]]; then
        ui_title "$ICON_PACKAGE Seeding tripwire from installed AUR packages"
        _tripwire_seed
        return 0
    fi

    # --all: review every currently-blocked installed AUR package
    if [[ "$all" == "true" ]]; then
        local -a installed=()
        mapfile -t installed < <(pacman -Qmq 2>/dev/null)
        local blocked
        blocked=$(_tripwire_scan "${installed[@]}")
        if [[ -z "$blocked" ]]; then
            ui_success "No AUR packages are blocked — nothing to approve"
            return 0
        fi
        while IFS= read -r name; do
            [[ -n "$name" ]] && _approve_one "$name"
        done <<< "$blocked"
        return 0
    fi

    # Explicit package names
    if [[ ${#names[@]} -eq 0 ]]; then
        ui_error "No packages specified"
        ui_info "Usage: package-manager approve <package>... | --all | --seed"
        return 1
    fi

    local name
    for name in "${names[@]}"; do
        _approve_one "$name"
    done
}
