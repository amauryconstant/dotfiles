#!/usr/bin/env bash

# Script: cmd-find.sh
# Purpose: Find which module(s) contain a package
# Requirements: yq

cmd_find() {
    local package="$1"
    local json_output=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                json_output=true
                shift
                ;;
            *)
                package="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$package" ]]; then
        ui_error "Usage: package-manager find <package> [--json]"
        return 1
    fi

    _check_yq_dependency || return 1

    if [[ "$json_output" != "true" ]]; then
        ui_title "🔍 Finding package: $package"
    fi

    local found=0
    local -a results=()

    # Search all modules
    while IFS= read -r module; do
        local packages
        packages=$(_get_module_packages "$module")

        # Check if package exists in module (handle both string and object formats)
        if echo "$packages" | grep -qE "^${package}$|^name: ${package}$"; then
            ((found++))

            local desc
            local enabled
            desc=$(yq eval --arg mod "$module" '.packages.modules[$mod].description' "$PACKAGES_FILE")
            enabled=$(yq eval --arg mod "$module" '.packages.modules[$mod].enabled' "$PACKAGES_FILE")

            if [[ "$json_output" == "true" ]]; then
                results+=("{\"module\": \"$module\", \"description\": \"$desc\", \"enabled\": $enabled}")
            else
                ui_success "Found in module: $module"
                ui_kv "Description" "$desc"
                ui_kv "Enabled" "$enabled"
                echo ""
            fi
        fi
    done < <(_get_modules)

    # Output results
    if [[ $found -eq 0 ]]; then
        if [[ "$json_output" == "true" ]]; then
            echo '{"found": false, "package": "'"$package"'", "modules": []}'
        else
            ui_warning "Package '$package' not found in any module"
        fi
        return 1
    else
        if [[ "$json_output" == "true" ]]; then
            echo '{"found": true, "package": "'"$package"'", "count": '"$found"', "modules": ['"$(IFS=,; echo "${results[*]}")"']}'
        else
            ui_success "Found in $found module(s)"
        fi
    fi
}
