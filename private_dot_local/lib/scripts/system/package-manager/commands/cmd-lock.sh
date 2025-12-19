#!/usr/bin/env bash

# Script: cmd-lock.sh
# Purpose: Generate package lockfile
# Requirements: yq

cmd_lock() {
    local quiet=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q)
                quiet=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    _check_yq_dependency || return 1

    [[ "$quiet" == "false" ]] && ui_title "$ICON_LOCK Generating Package Lockfile"
    [[ "$quiet" == "false" ]] && echo ""

    local timestamp=$(date -Iseconds)
    local hostname
    if command -v hostname >/dev/null 2>&1; then
        hostname=$(hostname)
    elif [[ -r /proc/sys/kernel/hostname ]]; then
        hostname=$(cat /proc/sys/kernel/hostname)
    else
        hostname="localhost"
    fi

    cat > "$LOCKFILE" << EOF
# Generated: $timestamp
# Host: $hostname
# Purpose: Reproducible package versions (like NixOS flake.lock)

packages:
EOF

    # Optimized: Try state file first (fastest)
    declare -A versions_from_state

    if [[ -f "$STATE_FILE" ]]; then
        [[ "$quiet" == "false" ]] && ui_step "Reading package versions from state file..."
        while IFS='|' read -r name ver; do
            [[ -n "$name" ]] && versions_from_state[$name]="$ver"
        done < <(yq eval '.packages[] | "\(.name)|\(.version)"' "$STATE_FILE" 2>/dev/null)
    fi

    # Fallback to batch pacman query if state file is empty
    local state_count
    state_count=${#versions_from_state[@]}

    if [[ ${state_count} -eq 0 ]]; then
        [[ "$quiet" == "false" ]] && ui_step "Querying installed versions (batch)..."
        while IFS=' ' read -r pkg ver; do
            [[ -n "$pkg" ]] && versions_from_state[$pkg]="$ver"
        done < <(pacman -Q 2>/dev/null)
        state_count=${#versions_from_state[@]}
    fi

    [[ "$quiet" == "false" ]] && ui_info "Cached ${state_count} package versions"

    # Process pacman packages
    local pkg_count=0
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        echo "  ${module}:" >> "$LOCKFILE"

        while IFS= read -r package; do
            # Skip flatpak packages
            if _is_flatpak "$package"; then
                continue
            fi

            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version _constraint_type <<< "$pkg_data"

            # Optimized: lookup instead of query
            local installed_version="${versions_from_state[$name]:-}"

            if [[ -n "$installed_version" ]]; then
                if _is_rolling_package "$name"; then
                    echo "    ${name}: \"${installed_version}\"  # rolling (-git package)" >> "$LOCKFILE"
                else
                    echo "    ${name}: \"${installed_version}\"" >> "$LOCKFILE"
                fi
                ((pkg_count++))
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

    # Process flatpak packages
    echo "" >> "$LOCKFILE"
    echo "flatpaks:" >> "$LOCKFILE"

    local flatpak_count=0
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        local has_flatpak=false
        while IFS= read -r package; do
            if _is_flatpak "$package"; then
                if [[ "$has_flatpak" == "false" ]]; then
                    echo "  ${module}:" >> "$LOCKFILE"
                    has_flatpak=true
                fi

                local app_id=$(_strip_flatpak_prefix "$package")
                local version=$(_get_flatpak_version "$app_id")

                if [[ -n "$version" ]]; then
                    echo "    ${app_id}: \"${version}\"" >> "$LOCKFILE"
                    ((flatpak_count++))
                fi
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

    if [[ "$quiet" == "false" ]]; then
        echo ""
        ui_success "Lockfile generated: $LOCKFILE"
        ui_info "Packages: $pkg_count | Flatpaks: $flatpak_count"
        ui_info "Commit this file to track your system's package state"
    fi
}
