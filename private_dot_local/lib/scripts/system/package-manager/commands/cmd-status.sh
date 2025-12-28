#!/usr/bin/env bash

# Script: cmd-status.sh
# Purpose: Display comprehensive package manager status
# Requirements: yq, pacman

cmd_status() {
    ui_title "$ICON_CHART Package Manager Status"

    # Load caches once at start
    _load_module_cache
    _load_pacman_version_cache

    # Module Status
    ui_step "Modules"
    local total_modules=$(yq eval '.packages.modules | keys | length' "$PACKAGES_FILE")
    local enabled_count=0
    local disabled_count=0

    # Build module table
    {
        printf "Module\tPackages\tStatus\tDescription\n"

        # Enabled modules
        while IFS= read -r module; do
            ((enabled_count++))
            local pkg_count=$(_get_module_packages_cached "$module" | wc -l)
            local description
            description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE")
            printf "%s\t%d\tEnabled\t%s\n" "$module" "$pkg_count" "$description"
        done < <(_get_enabled_modules_cached)

        # Disabled modules
        local disabled_modules=$(yq eval '.packages.modules | to_entries | .[] | select(.value.enabled == false) | .key' "$PACKAGES_FILE" 2>/dev/null)
        if [[ -n "$disabled_modules" ]]; then
            while IFS= read -r module; do
                ((disabled_count++))
                local description
                description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE")
                printf "%s\t-\tDisabled\t%s\n" "$module" "$description"
            done <<< "$disabled_modules"
        fi
    } | ui_table

    echo ""
    ui_success "Total: $total_modules modules ($enabled_count enabled, $disabled_count disabled)"

    # Version Constraints
    echo ""
    ui_step "Version Constraints"

    local pinned_count=0
    local violations=0

    while IFS= read -r module; do
        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint_cached "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            if [[ "$constraint_type" != "none" ]]; then
                ((pinned_count++))

                local installed=$(_get_cached_package_version "$name")
                local status="$ICON_UNKNOWN"
                local violates=false

                if [[ -n "$installed" ]]; then
                    # Use centralized constraint checking
                    if _check_constraint_satisfaction "$installed" "$version" "$constraint_type"; then
                        status="$ICON_CHECK"
                    else
                        status="$ICON_ERROR"
                        violates=true
                    fi

                    if [[ "$violates" == "true" ]]; then
                        ((violations++))
                        ui_error "  $status $name: $constraint_type $version (have: $installed)"
                    else
                        ui_success "  $status $name: $constraint_type $version"
                    fi
                else
                    ui_warning "  $ICON_UNKNOWN $name: $constraint_type $version (not installed)"
                fi
            fi
        done < <(_get_module_packages_cached "$module")
    done < <(_get_enabled_modules_cached)

    if [[ $pinned_count -eq 0 ]]; then
        ui_info "  No version constraints set"
    else
        echo ""
        if [[ $violations -eq 0 ]]; then
            ui_success "$pinned_count constraints (all satisfied)"
        else
            ui_warning "$pinned_count constraints ($violations violations)"
        fi
    fi

    # Package Health
    echo ""
    ui_step "Package Health"

    local pacman_count=$(pacman -Q 2>/dev/null | wc -l)
    local flatpak_count=$(flatpak list --app 2>/dev/null | wc -l)
    local state_count=$(yq eval '.packages | length' "$STATE_FILE" 2>/dev/null || echo 0)

    ui_info "  $ICON_BULLET Pacman: $pacman_count packages"
    ui_info "  $ICON_BULLET Flatpak: $flatpak_count packages"
    ui_info "  $ICON_BULLET State file: $state_count tracked"

    # Orphaned packages (optimized with hash set - O(M*P + N) instead of O(N*M*P))
    local orphan_count=0

    # Build declared package set once
    declare -A declared_set
    while IFS= read -r module; do
        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint_cached "$package")
            IFS='|' read -r name _ _ <<< "$pkg_data"
            # Strip flatpak: prefix for comparison
            local name_stripped="${name#flatpak:}"
            [[ -n "$name_stripped" ]] && declared_set[$name_stripped]=1
        done < <(_get_module_packages_cached "$module")
    done < <(_get_enabled_modules_cached)

    # Then O(N) lookup for orphans
    while IFS= read -r pkg_name; do
        if [[ -z "${declared_set[$pkg_name]:-}" ]]; then
            ((orphan_count++))
        fi
    done < <(yq eval '.packages[].name' "$STATE_FILE" 2>/dev/null)

    if [[ $orphan_count -gt 0 ]]; then
        ui_warning "  $ICON_WARNING  Orphans: $orphan_count packages (use 'sync --prune')"
    else
        ui_success "  $ICON_CHECK No orphaned packages"
    fi

    # Rolling packages (reuse declared_set from orphan detection for efficiency)
    local rolling_count=0
    for pkg_name in "${!declared_set[@]}"; do
        if _is_rolling_package "$pkg_name"; then
            ((rolling_count++))
        fi
    done

    ui_info "  $ICON_BULLET Rolling packages: $rolling_count (-git suffix)"

    # State File Info
    echo ""
    ui_step "State Files"

    # Auto-initialize if missing (prevents "not found" error)
    _init_state_file

    if [[ -f "$STATE_FILE" ]]; then
        local state_count=$(yq eval '.packages | length' "$STATE_FILE" 2>/dev/null || echo 0)
        local state_size=$(du -h "$STATE_FILE" | awk '{print $1}')
        local last_modified=$(stat -c %y "$STATE_FILE" | cut -d' ' -f1,2 | cut -d'.' -f1)

        if [[ $state_count -eq 0 ]]; then
            ui_warning "  $ICON_WARNING State file: Empty (run 'package-manager sync' to populate)"
        else
            ui_success "  $ICON_CHECK State file: $state_size ($state_count packages, last modified: $last_modified)"
        fi
    else
        ui_error "  $ICON_ERROR State file: Creation failed"
    fi

    if [[ -f "$LOCKFILE" ]]; then
        local lock_size=$(du -h "$LOCKFILE" | awk '{print $1}')
        local age_days=$(( ($(date +%s) - $(stat -c %Y "$LOCKFILE")) / 86400 ))
        ui_success "  $ICON_CHECK Lockfile: $lock_size (${age_days}d old)"
    else
        ui_warning "  $ICON_WARNING  Lockfile: Not found (run 'lock' to create)"
    fi

    # Lockfile Analysis
    if [[ -f "$LOCKFILE" ]]; then
        echo ""
        ui_step "Lockfile Status"

        # Check staleness
        _check_lockfile_staleness
        local _stale_status=$?

        # Drift detection
        if _read_lockfile; then
            local drift_count=0
            declare -A current_versions

            # Cache current versions
            while IFS=' ' read -r pkg ver; do
                [[ -n "$pkg" ]] && current_versions[$pkg]="$ver"
            done < <(pacman -Q 2>/dev/null)

            # Count drifted packages
            # shellcheck disable=SC2154  # lockfile_versions populated by _read_lockfile
            for pkg in "${!lockfile_versions[@]}"; do
                local current_ver="${current_versions[$pkg]:-}"
                local locked_ver="${lockfile_versions[$pkg]:-}"

                if [[ -n "$current_ver" ]] && [[ "$current_ver" != "$locked_ver" ]]; then
                    ((drift_count++))
                fi
            done

            if [[ $drift_count -eq 0 ]]; then
                ui_success "  $ICON_CHECK No drift from lockfile"
            else
                ui_warning "  $ICON_WARNING  Drift: $drift_count packages differ from lockfile"
                ui_info "     Run 'package-manager lock' to update"
            fi
        fi
    fi

    echo ""
    ui_success "Status check complete"
    return 0
}
