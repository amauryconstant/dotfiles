#!/usr/bin/env bash

# Script: cmd-validate.sh
# Purpose: Validate packages.yaml configuration
# Requirements: yq

cmd_validate() {
    local check_packages=false
    local check_lockfile=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check-packages)
                check_packages=true
                shift
                ;;
            --check-lockfile)
                check_lockfile=true
                shift
                ;;
            *)
                ui_error "Unknown flag: $1"
                ui_info "Usage: package-manager validate [--check-packages] [--check-lockfile]"
                return 1
                ;;
        esac
    done

    ui_title "$ICON_SEARCH Validating packages.yaml"

    local errors=0
    local warnings=0

    # 1. YAML Syntax
    ui_step "Checking YAML syntax..."
    if ! _with_context "Validating YAML syntax of $PACKAGES_FILE" \
         yq eval '.' "$PACKAGES_FILE" >/dev/null; then
        ((errors++))
    else
        ui_success "YAML syntax valid"
    fi

    # 2. Module Structure
    ui_step "Validating module structure..."

    while IFS= read -r module; do
        # Check required fields
        local has_enabled
        local has_description
        local has_packages
        has_enabled=$(MOD="$module" yq eval '.packages.modules[env(MOD)] | has("enabled")' "$PACKAGES_FILE")
        has_description=$(MOD="$module" yq eval '.packages.modules[env(MOD)] | has("description")' "$PACKAGES_FILE")
        has_packages=$(MOD="$module" yq eval '.packages.modules[env(MOD)] | has("packages")' "$PACKAGES_FILE")

        if [[ "$has_enabled" != "true" ]]; then
            ui_error "Module '$module': Missing 'enabled' field"
            ((errors++))
        else
            local enabled_value
            enabled_value=$(MOD="$module" yq eval '.packages.modules[env(MOD)].enabled' "$PACKAGES_FILE")
            if [[ "$enabled_value" != "true" ]] && [[ "$enabled_value" != "false" ]]; then
                ui_error "Module '$module': 'enabled' must be boolean (true/false)"
                ((errors++))
            fi
        fi

        if [[ "$has_description" != "true" ]]; then
            ui_warning "Module '$module': Missing 'description' field"
            ((warnings++))
        fi

        if [[ "$has_packages" != "true" ]]; then
            ui_error "Module '$module': Missing 'packages' field"
            ((errors++))
        else
            local pkg_count=$(_get_module_packages "$module" | wc -l)
            if [[ $pkg_count -eq 0 ]]; then
                ui_warning "Module '$module': Empty package list"
                ((warnings++))
            fi
        fi
    done < <(_get_modules)

    if [[ $errors -eq 0 ]] && [[ $warnings -eq 0 ]]; then
        ui_success "Module structure valid"
    fi

    # 3. Package Format
    ui_step "Validating package format..."

    local format_errors=0
    while IFS= read -r module; do
        while IFS= read -r package; do
            # Try to parse constraint
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            # Check for invalid characters in name
            if [[ "$name" =~ [[:space:]] ]]; then
                ui_error "Module '$module': Package name contains spaces: '$name'"
                ((format_errors++))
            fi

            # Validate constraint syntax
            if [[ -n "$version" ]]; then
                case "$constraint_type" in
                    "exact"|"minimum"|"maximum")
                        # Valid
                        ;;
                    *)
                        ui_error "Module '$module': Invalid constraint type for '$name': $constraint_type"
                        ((format_errors++))
                        ;;
                esac
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_modules)

    if [[ $format_errors -eq 0 ]]; then
        ui_success "Package format valid"
    else
        ((errors += format_errors))
    fi

    # 4. Conflict Detection
    ui_step "Checking module conflicts..."

    local conflict_errors=0
    while IFS= read -r module; do
        local conflicts=$(_get_module_conflicts "$module")

        if [[ -n "$conflicts" ]]; then
            while IFS= read -r conflict; do
                # Check if conflict module exists
                if ! _get_modules | grep -q "^${conflict}$"; then
                    ui_error "Module '$module': Conflict references non-existent module '$conflict'"
                    ((conflict_errors++))
                fi

                # Check if both modules are enabled
                if _is_module_enabled "$module" && _is_module_enabled "$conflict"; then
                    ui_error "Conflict violation: Both '$module' and '$conflict' are enabled"
                    ((conflict_errors++))
                fi

                # Check for circular conflicts
                local reverse_conflicts=$(_get_module_conflicts "$conflict")
                if echo "$reverse_conflicts" | grep -q "^${module}$"; then
                    # This is expected, not an error
                    :
                fi
            done <<< "$conflicts"
        fi
    done < <(_get_modules)

    if [[ $conflict_errors -eq 0 ]]; then
        ui_success "No conflict violations"
    else
        ((errors += conflict_errors))
    fi

    # 5. Duplicate Detection
    ui_step "Checking for duplicate packages..."

    local -A pkg_locations
    local dup_errors=0

    while IFS= read -r module; do
        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            if [[ -v pkg_locations[$name] ]]; then
                ui_error "Duplicate package '$name' in modules: ${pkg_locations[$name]} and $module"
                ((dup_errors++))
            else
                [[ -n "$name" ]] && pkg_locations[$name]="$module"
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_modules)

    if [[ $dup_errors -eq 0 ]]; then
        ui_success "No duplicate packages"
    else
        ((errors += dup_errors))
    fi

    # 6. Package Existence (if --check-packages)
    if [[ "$check_packages" == "true" ]]; then
        ui_step "Checking package existence (this may take a while)..."

        local -a all_packages=()
        while IFS= read -r module; do
            while IFS= read -r package; do
                local pkg_data=$(_parse_package_constraint "$package")
                IFS='|' read -r name version constraint_type <<< "$pkg_data"

                # Skip flatpak packages for now
                if [[ "$name" != flatpak:* ]]; then
                    all_packages+=("$name")
                fi
            done < <(_get_module_packages "$module")
        done < <(_get_enabled_modules)

        local invalid=$(_check_packages_batch "${all_packages[@]}")
        if [[ -n "$invalid" ]]; then
            ui_error "Invalid packages found:"
            echo "$invalid" | while IFS= read -r pkg; do
                ui_error "  • $pkg"
            done
            ((errors++))
        else
            ui_success "All packages exist in repos/AUR"
        fi
    fi

    # Lockfile Validation
    if [[ "$check_lockfile" == "true" ]]; then
        echo ""
        ui_step "Validating lockfile..."

        if [[ ! -f "$LOCKFILE" ]]; then
            ui_error "Lockfile not found"
            ui_info "Run 'package-manager lock' to generate lockfile"
            ((errors++))
        else
            # Parse lockfile
            if ! _with_context "Validating lockfile YAML syntax at $LOCKFILE" \
                 yq eval '.' "$LOCKFILE" >/dev/null; then
                ((errors++))
            else
                ui_success "Lockfile syntax valid"
            fi

            # Check staleness
            _check_lockfile_staleness
            local stale=$?
            if [[ $stale -eq 2 ]]; then
                ui_error "Lockfile is critically stale (>90 days old)"
                ((errors++))
            elif [[ $stale -eq 1 ]]; then
                ui_warning "Lockfile is stale (>30 days old)"
                ((warnings++))
            fi
        fi
    fi

    # Final Summary
    echo ""
    ui_title "Validation Summary"
    [[ $errors -gt 0 ]] && ui_error "  Errors: $errors" || ui_info "  Errors: $errors"
    [[ $warnings -gt 0 ]] && ui_warning "  Warnings: $warnings" || ui_info "  Warnings: $warnings"

    if [[ $errors -eq 0 ]]; then
        ui_success "Validation passed!"
        return 0
    else
        ui_error "Validation failed with $errors errors"
        return 1
    fi
}
