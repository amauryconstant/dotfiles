#!/usr/bin/env bash

# Script: backup-manager.sh
# Purpose: Backup integration (Timeshift/Snapper)
# Requirements: timeshift or snapper (optional)

# =============================================================================
# BACKUP TOOL DETECTION
# =============================================================================

# Detect available backup tool (timeshift or snapper)
# Returns: Tool name or empty string if none available
_get_backup_tool() {
    # Check for explicit preference in packages.yaml
    local configured=$(yq eval '.backup_tool // ""' "$PACKAGES_FILE" 2>/dev/null)

    if [[ -n "$configured" ]] && [[ "$configured" != "null" ]]; then
        if command -v "$configured" >/dev/null 2>&1; then
            echo "$configured"
            return
        fi
    fi

    # Auto-detect: prefer timeshift, fallback to snapper
    if command -v timeshift >/dev/null 2>&1; then
        echo "timeshift"
    elif command -v snapper >/dev/null 2>&1; then
        echo "snapper"
    else
        echo ""
    fi
}

# Get snapper config name from packages.yaml (default: root)
_get_snapper_config() {
    local snapper_config=$(yq eval '.packages.snapper_config // "root"' "$PACKAGES_FILE" 2>/dev/null)
    echo "$snapper_config"
}

# =============================================================================
# BACKUP CREATION
# =============================================================================

# Create optional backup before sync (supports timeshift and snapper)
# Usage: _create_backup
# Returns: 0 on success or skip, 1 on failure (non-fatal)
_create_backup() {
    local backup_tool=$(_get_backup_tool)

    # No backup tool available
    if [[ -z "$backup_tool" ]]; then
        return 0  # Skip silently if not installed
    fi

    # Skip backup prompt if not in interactive terminal
    if [[ ! -t 0 ]]; then
        [[ "$VERBOSE" == "true" ]] && ui_info "Non-interactive mode: skipping backup prompt"
        return 0
    fi

    ui_info "$backup_tool backup available"

    if ui_confirm "Create system backup before sync?"; then
        ui_step "Creating $backup_tool backup..."

        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local comment="package-manager sync - $timestamp"

        case "$backup_tool" in
            timeshift)
                if sudo timeshift --create --comments "$comment" --scripted; then
                    ui_success "Timeshift backup created successfully"
                    return 0
                else
                    ui_warning "Timeshift backup failed (continuing anyway)"
                    return 1
                fi
                ;;
            snapper)
                local snapper_config=$(_get_snapper_config)
                if sudo snapper -c "$snapper_config" create -d "$comment"; then
                    ui_success "Snapper snapshot created successfully (config: $snapper_config)"
                    return 0
                else
                    ui_warning "Snapper snapshot failed (continuing anyway)"
                    return 1
                fi
                ;;
            *)
                ui_warning "Unknown backup tool: $backup_tool"
                return 1
                ;;
        esac
    else
        ui_info "Skipping backup"
        return 0
    fi
}

