#!/usr/bin/env bash

# Script: cmd-status.sh
# Purpose: Display comprehensive package manager status
# Requirements: yq, pacman

cmd_status() {
    ui_title "📊 Package Manager Status"

    # Module Status
    ui_step "Modules"
    local total_modules=$(yq eval '.packages.modules | keys | length' "$PACKAGES_FILE")
    local enabled_count=0
    local disabled_count=0

    while IFS= read -r module; do
        ((enabled_count++))
        local pkg_count=$(_get_module_packages "$module" | wc -l)
        local description=$(yq eval --arg mod "$module" '.packages.modules[$mod].description' "$PACKAGES_FILE")

        ui_success "  ✓ $module ($pkg_count packages)"
        ui_info "    $description"

        # Check for conflicts
        local conflicts=$(_get_module_conflicts "$module")
        if [[ -n "$conflicts" ]]; then
            ui_warning "    ⚠️  Conflicts: $conflicts"
        fi
    done < <(_get_enabled_modules)

    local disabled_modules=$(yq eval '.packages.modules | to_entries | .[] | select(.value.enabled == false) | .key' "$PACKAGES_FILE" 2>/dev/null)
    if [[ -n "$disabled_modules" ]]; then
        echo ""
        ui_info "Disabled modules:"
        while IFS= read -r module; do
            ((disabled_count++))
            ui_info "  ✗ $module" | ui_color gray
        done <<< "$disabled_modules"
    fi

    echo ""
    ui_success "Total: $total_modules modules ($enabled_count enabled, $disabled_count disabled)"

    # Version Constraints
    echo ""
    ui_step "Version Constraints"

    local pinned_count=0
    local violations=0

    # Pre-load version cache for performance (batch query instead of N individual queries)
    _load_pacman_version_cache

    while IFS= read -r module; do
        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            if [[ "$constraint_type" != "none" ]]; then
                ((pinned_count++))

                local installed=$(_get_cached_package_version "$name")
                local status="❓"
                local violates=false

                if [[ -n "$installed" ]]; then
                    case "$constraint_type" in
                        "exact")
                            if [[ "$installed" == "$version" ]]; then
                                status="✓"
                            else
                                status="❌"
                                violates=true
                            fi
                            ;;
                        "minimum")
                            _compare_versions "$installed" "$version"
                            local cmp=$?
                            if [[ $cmp -eq 1 ]] || [[ $cmp -eq 0 ]]; then
                                status="✓"
                            else
                                status="❌"
                                violates=true
                            fi
                            ;;
                        "maximum")
                            _compare_versions "$installed" "$version"
                            local cmp=$?
                            if [[ $cmp -eq 2 ]]; then
                                status="✓"
                            else
                                status="❌"
                                violates=true
                            fi
                            ;;
                    esac

                    if [[ "$violates" == "true" ]]; then
                        ((violations++))
                        ui_error "  $status $name: $constraint_type $version (have: $installed)"
                    else
                        ui_success "  $status $name: $constraint_type $version"
                    fi
                else
                    ui_warning "  ❓ $name: $constraint_type $version (not installed)"
                fi
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

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

    ui_info "  • Pacman: $pacman_count packages"
    ui_info "  • Flatpak: $flatpak_count packages"
    ui_info "  • State file: $state_count tracked"

    # Orphaned packages (optimized with hash set - O(M*P + N) instead of O(N*M*P))
    local orphan_count=0

    # Build declared package set once
    declare -A declared_set
    while IFS= read -r module; do
        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name _ _ <<< "$pkg_data"
            # Strip flatpak: prefix for comparison
            declared_set["${name#flatpak:}"]=1
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

    # Then O(N) lookup for orphans
    while IFS= read -r pkg_name; do
        if [[ -z "${declared_set[$pkg_name]:-}" ]]; then
            ((orphan_count++))
        fi
    done < <(yq eval '.packages[].name' "$STATE_FILE" 2>/dev/null)

    if [[ $orphan_count -gt 0 ]]; then
        ui_warning "  ⚠️  Orphans: $orphan_count packages (use 'sync --prune')"
    else
        ui_success "  ✓ No orphaned packages"
    fi

    # Rolling packages (reuse declared_set from orphan detection for efficiency)
    local rolling_count=0
    for pkg_name in "${!declared_set[@]:-}"; do
        if _is_rolling_package "$pkg_name"; then
            ((rolling_count++))
        fi
    done

    ui_info "  • Rolling packages: $rolling_count (-git suffix)"

    # State File Info
    echo ""
    ui_step "State Files"

    if [[ -f "$STATE_FILE" ]]; then
        local state_size=$(du -h "$STATE_FILE" | awk '{print $1}')
        local last_modified=$(stat -c %y "$STATE_FILE" | cut -d' ' -f1,2 | cut -d'.' -f1)
        ui_success "  ✓ State file: $state_size (last modified: $last_modified)"
    else
        ui_error "  ❌ State file: Not found"
    fi

    if [[ -f "$LOCKFILE" ]]; then
        local lock_size=$(du -h "$LOCKFILE" | awk '{print $1}')
        local age_days=$(( ($(date +%s) - $(stat -c %Y "$LOCKFILE")) / 86400 ))
        ui_success "  ✓ Lockfile: $lock_size (${age_days}d old)"
    else
        ui_warning "  ⚠️  Lockfile: Not found (run 'lock' to create)"
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
                current_versions["$pkg"]="$ver"
            done < <(pacman -Q 2>/dev/null)

            # Count drifted packages
            for pkg in "${!lockfile_versions[@]:-}"; do
                local current_ver="${current_versions[$pkg]:-}"
                local locked_ver="${lockfile_versions[$pkg]}"

                if [[ -n "$current_ver" ]] && [[ "$current_ver" != "$locked_ver" ]]; then
                    ((drift_count++))
                fi
            done

            if [[ $drift_count -eq 0 ]]; then
                ui_success "  ✓ No drift from lockfile"
            else
                ui_warning "  ⚠️  Drift: $drift_count packages differ from lockfile"
                ui_info "     Run 'package-manager lock' to update"
            fi
        fi
    fi

    echo ""
    ui_success "Status check complete"
    return 0
}
