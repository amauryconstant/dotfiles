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

    # Load module cache once at start
    _load_module_cache

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

    # Single-pass collection: Iterate modules once and collect both pacman and flatpak packages
    declare -A pacman_locks
    declare -A flatpak_locks
    local pkg_count=0
    local flatpak_count=0

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint_cached "$package")
            IFS='|' read -r name _version _constraint_type <<< "$pkg_data"

            if _is_flatpak "$name"; then
                # Flatpak package
                local app_id=$(_strip_flatpak_prefix "$name")
                local flatpak_version=$(_get_flatpak_version "$app_id")

                if [[ -n "$flatpak_version" ]]; then
                    # Append to module's flatpak list (newline-separated)
                    flatpak_locks[$module]+="${app_id}|${flatpak_version}"$'\n'
                    ((flatpak_count++))
                fi
            else
                # Pacman package
                local installed_version="${versions_from_state[$name]:-}"

                if [[ -n "$installed_version" ]]; then
                    local rolling_flag=""
                    if _is_rolling_package "$name"; then
                        rolling_flag="rolling"
                    fi
                    # Append to module's pacman list (newline-separated)
                    pacman_locks[$module]+="${name}|${installed_version}|${rolling_flag}"$'\n'
                    ((pkg_count++))
                fi
            fi
        done < <(_get_module_packages_cached "$module")
    done < <(_get_enabled_modules_cached)

    # Write pacman packages section
    if [[ ${#pacman_locks[@]} -gt 0 ]]; then
        for module in $(printf '%s\n' "${!pacman_locks[@]}" | sort); do
            local pkg_list="${pacman_locks[$module]}"
            [[ -z "$pkg_list" ]] && continue

            echo "  ${module}:" >> "$LOCKFILE"

            # Process stored packages (newline-separated)
            while IFS='|' read -r name ver rolling; do
                [[ -z "$name" ]] && continue
                if [[ "$rolling" == "rolling" ]]; then
                    echo "    ${name}: \"${ver}\"  # rolling (-git package)" >> "$LOCKFILE"
                else
                    echo "    ${name}: \"${ver}\"" >> "$LOCKFILE"
                fi
            done <<< "$pkg_list"
        done
    fi

    # Write flatpak packages section
    echo "" >> "$LOCKFILE"
    echo "flatpaks:" >> "$LOCKFILE"

    if [[ ${#flatpak_locks[@]} -gt 0 ]]; then
        for module in $(printf '%s\n' "${!flatpak_locks[@]}" | sort); do
            local flatpak_list="${flatpak_locks[$module]}"
            [[ -z "$flatpak_list" ]] && continue

            echo "  ${module}:" >> "$LOCKFILE"

            # Process stored flatpaks (newline-separated)
            while IFS='|' read -r app_id ver; do
                [[ -z "$app_id" ]] && continue
                echo "    ${app_id}: \"${ver}\"" >> "$LOCKFILE"
            done <<< "$flatpak_list"
        done
    fi

    if [[ "$quiet" == "false" ]]; then
        echo ""
        ui_success "Lockfile generated: $LOCKFILE"
        ui_info "Packages: $pkg_count | Flatpaks: $flatpak_count"
        ui_info "Commit this file to track your system's package state"
    fi
}
