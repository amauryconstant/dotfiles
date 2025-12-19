#!/usr/bin/env bash

# Script: cmd-versions.sh
# Purpose: Display version information for a package
# Requirements: yq, pacman

cmd_versions() {
    local package="$1"
    _check_yq_dependency || return 1

    if [[ -z "$package" ]]; then
        ui_error "Package name required"
        ui_info "Usage: package-manager versions <package>"
        return 1
    fi

    ui_title "📊 Version Information: $package"
    echo ""

    # Check if it's a flatpak
    if _is_flatpak "$package"; then
        local app_id=$(_strip_flatpak_prefix "$package")

        # Installed version
        local installed=$(_get_flatpak_version "$app_id")
        if [[ -n "$installed" ]]; then
            ui_info "Installed: $installed"
        else
            ui_warning "Not installed"
        fi
    else
        # Installed version
        local installed=$(_get_package_version "$package")
        if [[ -n "$installed" ]]; then
            ui_info "Installed: $installed"
        else
            ui_warning "Not installed"
        fi

        # Lockfile version
        if _read_lockfile && [[ -n "${lockfile_versions[$package]}" ]]; then
            local lock_ver="${lockfile_versions[$package]}"
            if [[ "$lock_ver" == "$installed" ]]; then
                ui_success "Lockfile:  $lock_ver  ✓ Matches"
            else
                ui_warning "Lockfile:  $lock_ver  (drift detected)"
            fi
        else
            ui_info "Lockfile:  Not in lockfile"
        fi

        # Available version
        local available=$(_get_repo_version "$package")
        if [[ -n "$available" ]]; then
            ui_info "Available: $available"
        fi

        # Rolling package check
        if _is_rolling_package "$package"; then
            echo ""
            ui_warning "⚠️  This is a -git package (rolling release)"
            ui_info "Version pinning not recommended for rolling packages"
        fi

        # Cached versions
        echo ""
        ui_info "Versions in local cache:"
        local cache_dir="/var/cache/pacman/pkg"
        local cache_found=false
        for pkg_file in ${cache_dir}/${package}-*.pkg.tar.zst; do
            if [[ -f "$pkg_file" ]]; then
                local basename=$(basename "$pkg_file")
                local version_str=$(echo "$basename" | sed "s/^${package}-//;s/-$(uname -m)\.pkg\.tar\.zst$//")
                echo "  • $version_str"
                cache_found=true
            fi
        done
        if [[ "$cache_found" == "false" ]]; then
            echo "  (none)"
        fi
    fi

    # Check for constraint in modules
    echo ""
    ui_info "Version constraint:"
    local has_constraint=false
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        local constraint=$(yq eval --arg mod "$module" --arg pkg "$package" '.packages.modules[$mod].packages[] | select(.name == $pkg) | .version' "$PACKAGES_FILE" 2>/dev/null)

        if [[ -n "$constraint" && "$constraint" != "null" ]]; then
            ui_success "Pinned to: $constraint (in module '$module')"
            has_constraint=true
            break
        fi
    done < <(_get_enabled_modules)

    if [[ "$has_constraint" == "false" ]]; then
        ui_info "No constraint (will use latest available)"
    fi
}
