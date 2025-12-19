#!/usr/bin/env bash

# Script: cmd-merge.sh
# Purpose: Merge unmanaged packages into modules
# Requirements: yq, pacman

cmd_merge() {
    local dry_run=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            *)
                ui_error "Unknown flag: $1"
                ui_info "Usage: package-manager merge [--dry-run]"
                return 1
                ;;
        esac
    done

    _check_yq_dependency || return 1

    ui_title "📦 Merge Unmanaged Packages"
    echo ""

    ui_step "Scanning explicitly installed packages..."
    local installed_packages=$(pacman -Qeq 2>/dev/null)
    local installed_count=$(echo "$installed_packages" | wc -l)
    ui_info "Found $installed_count explicitly installed packages"

    ui_step "Loading declared packages from modules..."
    local -a declared_packages=()

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name _version _constraint_type <<< "$pkg_data"

            # Strip flatpak: prefix for comparison
            local name_stripped="${name#flatpak:}"
            declared_packages+=("$name_stripped")
        done < <(_get_module_packages "$module")
    done < <(_get_modules)

    ui_info "Found ${#declared_packages[@]} declared packages across all modules"

    # Find unmanaged packages (optimized with hash set - O(M + N) instead of O(N*M))
    ui_step "Identifying unmanaged packages..."
    local -a unmanaged=()

    # Build declared set for O(1) lookups
    declare -A declared_set
    for pkg in "${declared_packages[@]}"; do
        declared_set["$pkg"]=1
    done

    # Then O(N) lookup for unmanaged
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue

        if [[ -z "${declared_set[$pkg]:-}" ]]; then
            unmanaged+=("$pkg")
        fi
    done <<< "$installed_packages"

    echo ""

    if [[ ${#unmanaged[@]} -eq 0 ]]; then
        ui_success "All explicitly installed packages are already managed!"
        return 0
    fi

    ui_warning "Found ${#unmanaged[@]} unmanaged packages:"
    echo ""

    for pkg in "${unmanaged[@]}"; do
        ui_info "  • $pkg"
    done

    echo ""

    if [[ "$dry_run" == "true" ]]; then
        ui_info "Dry run mode - no changes will be made"
        return 0
    fi

    # Interactive module selection
    if ! ui_confirm "Add these packages to a module?"; then
        ui_info "Cancelled"
        return 0
    fi

    # Module selection with fzf if available
    local selected_module
    if command -v fzf >/dev/null 2>&1; then
        # fzf-powered module selection with preview
        local -a fzf_input=()
        while IFS= read -r module; do
            [[ -z "$module" ]] && continue

            local description=$(yq eval --arg mod "$module" '.packages.modules[$mod].description' "$PACKAGES_FILE" 2>/dev/null)
            [[ -z "$description" || "$description" == "null" ]] && description="No description"

            local pkg_count=$(yq eval --arg mod "$module" '.packages.modules[$mod].packages | length' "$PACKAGES_FILE" 2>/dev/null)
            local enabled=$(yq eval --arg mod "$module" '.packages.modules[$mod].enabled' "$PACKAGES_FILE" 2>/dev/null)
            local status="[disabled]"
            [[ "$enabled" == "true" ]] && status="[enabled]"

            # Format: "module_name | description | (N packages) | status"
            printf -v line "%-20s | %-50s | (%2d packages) | %s" "$module" "$description" "$pkg_count" "$status"
            fzf_input+=("$line")
        done < <(_get_modules)

        if [[ ${#fzf_input[@]} -eq 0 ]]; then
            ui_error "No modules found in packages.yaml"
            return 1
        fi

        local selected_line
        selected_line=$(printf "%s\n" "${fzf_input[@]}" | \
            fzf --height=80% \
                --border=rounded \
                --prompt="Select target module: " \
                --header="ENTER: confirm | ESC: cancel" \
                --preview="yq eval '.packages.modules.{1}' '$PACKAGES_FILE' 2>/dev/null || echo 'No details available'" \
                --preview-window=right:60%:wrap)

        if [[ -z "$selected_line" ]]; then
            ui_info "Cancelled"
            return 0
        fi

        selected_module=$(echo "$selected_line" | awk '{print $1}')
    else
        # Fallback to numbered menu
        local -a module_list=()
        while IFS= read -r module; do
            [[ -z "$module" ]] && continue
            module_list+=("$module")
        done < <(_get_modules)

        if [[ ${#module_list[@]} -eq 0 ]]; then
            ui_error "No modules found in packages.yaml"
            return 1
        fi

        # Display module options
        ui_info "Available modules:"
        echo ""
        local i=1
        for module in "${module_list[@]}"; do
            local description=$(yq eval --arg mod "$module" '.packages.modules[$mod].description' "$PACKAGES_FILE" 2>/dev/null)
            [[ -z "$description" || "$description" == "null" ]] && description="No description"
            ui_info "  [$i] $module"
            ui_info "      $description"
            ((i++))
        done

        echo ""

        # Get user selection
        local selection
        while true; do
            read -p "Select module (1-${#module_list[@]}, or 'q' to cancel): " selection

            if [[ "$selection" == "q" ]] || [[ "$selection" == "Q" ]]; then
                ui_info "Cancelled"
                return 0
            fi

            if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#module_list[@]}" ]]; then
                break
            else
                ui_warning "Invalid selection, try again"
            fi
        done

        selected_module="${module_list[$((selection - 1))]}"
    fi
    echo ""
    ui_step "Adding packages to module: $selected_module"

    # Add packages to selected module
    local added=0
    for pkg in "${unmanaged[@]}"; do
        yq eval --arg mod "$selected_module" --arg pkg "$pkg" '.packages.modules[$mod].packages += [$pkg]' -i "$PACKAGES_FILE"
        ((added++))
    done

    echo ""
    ui_success "Added $added packages to module '$selected_module'"
    ui_info "Run 'package-manager sync' to reconcile system state"
}
