#!/usr/bin/env bash

# Script: cmd-outdated.sh
# Purpose: List packages violating version constraints
# Requirements: yq, vercmp

cmd_outdated() {
    _check_yq_dependency || return 1

    ui_title "$ICON_WARNING  Packages Violating Version Constraints"
    echo ""

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

            # Check constraint violation using vercmp
            local violates=false
            case "$constraint_type" in
                "exact")
                    if [[ "$installed" != "$version" ]]; then
                        violates=true
                    fi
                    ;;
                "minimum")
                    _compare_versions "$installed" "$version"
                    local cmp=$?
                    if [[ $cmp -eq 2 ]]; then  # installed < required
                        violates=true
                    fi
                    ;;
                "maximum")
                    _compare_versions "$installed" "$version"
                    local cmp=$?
                    if [[ $cmp -eq 1 ]] || [[ $cmp -eq 0 ]]; then  # installed >= maximum
                        violates=true
                    fi
                    ;;
            esac

            if [[ "$violates" == "true" ]]; then
                local op=""
                case "$constraint_type" in
                    "exact") op="==" ;;
                    "minimum") op=">=" ;;
                    "maximum") op="<" ;;
                esac

                ui_error "$name: installed=$installed, constraint=$op$version"
                ((violations++))
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

    if [[ "$violations" -eq 0 ]]; then
        ui_success "All packages meet version constraints"
        return 0
    else
        echo ""
        ui_warning "Found $violations constraint violations"
        ui_info "Run 'package-manager sync' to resolve"
        return 1
    fi
}
