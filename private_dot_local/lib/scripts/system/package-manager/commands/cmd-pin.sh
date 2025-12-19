#!/usr/bin/env bash

# Script: cmd-pin.sh
# Purpose: Pin and unpin package versions
# Requirements: yq

cmd_pin() {
    local package="$1"
    local version="$2"
    _check_yq_dependency || return 1

    if [[ -z "$package" ]]; then
        ui_error "Package name required"
        ui_info "Usage: package-manager pin <package> [version]"
        return 1
    fi

    # Check if it's a flatpak (strip prefix for checks)
    local is_flatpak=false
    local pkg_name="$package"
    if _is_flatpak "$package"; then
        is_flatpak=true
        pkg_name=$(_strip_flatpak_prefix "$package")
    fi

    # If no version specified, use currently installed version
    if [[ -z "$version" ]]; then
        if [[ "$is_flatpak" == "true" ]]; then
            version=$(_get_flatpak_version "$pkg_name")
            if [[ -z "$version" ]]; then
                ui_error "Flatpak '$pkg_name' not installed and no version specified"
                return 1
            fi
            ui_info "Pinning flatpak '$pkg_name' to current version: $version"
        else
            version=$(_get_package_version "$pkg_name")
            if [[ -z "$version" ]]; then
                ui_error "Package '$pkg_name' not installed and no version specified"
                return 1
            fi
            ui_info "Pinning '$pkg_name' to current version: $version"
        fi
    fi

    # Warn about rolling packages
    if _is_rolling_package "$pkg_name"; then
        ui_warning "$ICON_WARNING  '$pkg_name' is a -git package (rolling release)"
        ui_warning "Version pinning not recommended for rolling packages"
        ui_warning "The version will change with every build"
        echo ""

        if ! ui_confirm "Continue with pinning anyway?"; then
            ui_info "Cancelled"
            return 0
        fi
    fi

    # Find package in modules and update to object format
    local found=false
    local found_module=""

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        # Check if package exists in this module (as simple string)
        local has_simple
        has_simple=$(MOD="$module" PKG="$package" yq eval '.packages.modules[env(MOD)].packages[] | select(. == env(PKG))' "$PACKAGES_FILE" 2>/dev/null)

        if [[ -n "$has_simple" ]]; then
            # Found as simple string, convert to object with version
            local pkg_index
            pkg_index=$(MOD="$module" PKG="$package" yq eval '.packages.modules[env(MOD)].packages | to_entries | .[] | select(.value == env(PKG)) | .key' "$PACKAGES_FILE" | head -1)

            MOD="$module" IDX="$pkg_index" PKG="$package" VER="$version" yq eval '.packages.modules[env(MOD)].packages[env(IDX) | tonumber] = {"name": env(PKG), "version": env(VER)}' -i "$PACKAGES_FILE"
            found=true
            found_module="$module"
            break
        fi

        # Check if already exists as object
        local has_object
        has_object=$(MOD="$module" PKG="$package" yq eval '.packages.modules[env(MOD)].packages[] | select(.name == env(PKG))' "$PACKAGES_FILE" 2>/dev/null)

        if [[ -n "$has_object" ]]; then
            # Update existing object
            local pkg_index
            pkg_index=$(MOD="$module" PKG="$package" yq eval '.packages.modules[env(MOD)].packages | to_entries | .[] | select(.value.name == env(PKG)) | .key' "$PACKAGES_FILE" | head -1)

            MOD="$module" IDX="$pkg_index" VER="$version" yq eval '.packages.modules[env(MOD)].packages[env(IDX) | tonumber].version = env(VER)' -i "$PACKAGES_FILE"
            found=true
            found_module="$module"
            break
        fi
    done < <(_get_enabled_modules)

    if [[ "$found" == "false" ]]; then
        ui_error "Package '$package' not found in any enabled module"
        ui_info "Enable the module containing this package first"
        return 1
    fi

    ui_success "Pinned '$package' to version $version in module '$found_module'"
    ui_info "Run 'package-manager sync' to apply version constraint"
}

cmd_unpin() {
    local package="$1"
    _check_yq_dependency || return 1

    if [[ -z "$package" ]]; then
        ui_error "Package name required"
        ui_info "Usage: package-manager unpin <package>"
        return 1
    fi

    # Find and simplify package entry (object -> string)
    local found=false
    local found_module=""

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        # Check if exists as object with version
        local has_object
        has_object=$(MOD="$module" PKG="$package" yq eval '.packages.modules[env(MOD)].packages[] | select(.name == env(PKG))' "$PACKAGES_FILE" 2>/dev/null)

        if [[ -n "$has_object" ]]; then
            # Check if it has a version field
            local pkg_index
            local has_version
            pkg_index=$(MOD="$module" PKG="$package" yq eval '.packages.modules[env(MOD)].packages | to_entries | .[] | select(.value.name == env(PKG)) | .key' "$PACKAGES_FILE" | head -1)
            has_version=$(MOD="$module" IDX="$pkg_index" yq eval '.packages.modules[env(MOD)].packages[env(IDX) | tonumber] | has("version")' "$PACKAGES_FILE" 2>/dev/null)

            if [[ "$has_version" == "true" ]]; then
                # Replace object with simple string
                MOD="$module" IDX="$pkg_index" PKG="$package" yq eval '.packages.modules[env(MOD)].packages[env(IDX) | tonumber] = env(PKG)' -i "$PACKAGES_FILE"
                found=true
                found_module="$module"
                break
            fi
        fi
    done < <(_get_enabled_modules)

    if [[ "$found" == "false" ]]; then
        ui_warning "Package '$package' is not pinned"
        return 0
    fi

    ui_success "Unpinned '$package' in module '$found_module'"
    ui_info "Run 'package-manager sync' to use latest available version"
}
