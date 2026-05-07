#!/usr/bin/env bash

# Script: backup-manager.sh
# Purpose: Backup integration (Timeshift/Snapper)
# Requirements: timeshift or snapper (optional)

# =============================================================================
# ON-DEMAND SNAPSHOT PRUNING
# =============================================================================

# Prune oldest on-demand (O-tagged) Timeshift snapshots exceeding configured max.
# Reads on_demand max from globals.yaml; defaults to 5.
_prune_on_demand_snapshots() {
    local globals_file="$HOME/.local/share/chezmoi/.chezmoidata/globals.yaml"
    local max_count=5
    if [[ -f "$globals_file" ]]; then
        local parsed
        parsed=$(yq eval '.globals.timeshift.retention.on_demand // 5' "$globals_file" 2>/dev/null)
        [[ -n "$parsed" && "$parsed" != "null" ]] && max_count="$parsed"
    fi

    local all_snapshots
    all_snapshots=$(sudo timeshift --list --scripted 2>/dev/null \
        | awk '$2 == ">" && $4 == "O" {print $3}' || true)

    local count=0
    if [[ -n "$all_snapshots" ]]; then
        count=$(printf '%s\n' "$all_snapshots" | grep -c '[^[:space:]]' || true)
    fi
    count=${count:-0}

    if [[ "$count" -le "$max_count" ]]; then
        [[ "${VERBOSE:-false}" == "true" ]] && \
            ui_info "On-demand snapshots: $count/$max_count (within limit)"
        return 0
    fi

    local excess=$(( count - max_count ))
    ui_step "Pruning $excess excess on-demand snapshot(s) (keeping $max_count)..."

    local to_delete
    to_delete=$(printf '%s\n' "$all_snapshots" | head -n "$excess" || true)

    while IFS= read -r snapshot; do
        if sudo timeshift --delete --snapshot "$snapshot" --scripted >/dev/null 2>&1; then
            ui_success "Deleted: $snapshot"
        else
            ui_warning "Failed to delete: $snapshot"
        fi
    done <<< "$to_delete"
}

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
                # Direct call (sudo needs TTY access)
                if sudo timeshift --create --comments "$comment" --scripted; then
                    ui_success "Timeshift backup created successfully"
                    _prune_on_demand_snapshots
                    return 0
                else
                    ui_warning "Timeshift backup failed (continuing anyway)"
                    return 1
                fi
                ;;
            snapper)
                local snapper_config=$(_get_snapper_config)
                # Direct call (sudo needs TTY access)
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

