#!/usr/bin/env bash

# Script: cmd-outdated.sh
# Purpose: List packages violating version constraints
# Requirements: yq, vercmp

cmd_outdated() {
    _check_yq_dependency || return 1

    ui_title "$ICON_WARNING  Packages Violating Version Constraints"
    echo ""

    # Collect violations for table display
    local -a violation_data=()
    local violations=0

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        while IFS= read -r package; do
            # Skip flatpaks
            if _is_flatpak "$package"; then
                continue
            fi

            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            if [[ "$constraint_type" == "none" ]]; then
                continue
            fi

            local installed=$(_get_package_version "$name")
            if [[ -z "$installed" ]]; then
                continue
            fi

            # Check constraint violation using centralized logic
            if ! _check_constraint_satisfaction "$installed" "$version" "$constraint_type"; then
                local op=""
                case "$constraint_type" in
                    "exact") op="==" ;;
                    "minimum") op=">=" ;;
                    "maximum") op="<" ;;
                esac

                violation_data+=("$name|$installed|$op|$version|$module")
                ((violations++))
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

    if [[ "$violations" -eq 0 ]]; then
        ui_success "All packages meet version constraints"
        return 0
    else
        # Display violations as table
        {
            printf "Package\tInstalled\tConstraint\tRequired\tModule\n"
            for entry in "${violation_data[@]}"; do
                IFS='|' read -r pkg inst op req mod <<< "$entry"
                printf "%s\t%s\t%s\t%s\t%s\n" "$pkg" "$inst" "$op" "$req" "$mod"
            done
        } | ui_table

        echo ""
        ui_warning "Found $violations constraint violations"
        ui_info "Run 'package-manager sync' to resolve"
        return 1
    fi
}
