#!/usr/bin/env bash

# Script: cmd-search.sh
# Purpose: Interactive package search with fzf
# Requirements: fzf, paru, yq

cmd_search() {
    _check_yq_dependency || return 1

    # Check fzf availability (required)
    if ! command -v fzf >/dev/null 2>&1; then
        ui_error "fzf is required for interactive search"
        ui_info "Install: paru -S fzf"
        return 1
    fi

    # Check AUR helper
    local aur_helper
    aur_helper=$(_get_aur_helper)
    if [[ -z "$aur_helper" ]]; then
        ui_error "AUR helper (paru or yay) required"
        ui_info "Install: paru -S paru"
        return 1
    fi

    ui_title "🔍 Interactive Package Search"
    ui_step "Loading package database (repos + AUR)..."

    # Get all available packages (repos + AUR)
    local packages
    packages=$($aur_helper -Sl 2>/dev/null | awk '{print $2}' | sort -u)

    if [[ -z "$packages" ]]; then
        ui_error "Failed to load package database"
        return 1
    fi

    # Interactive selection with fzf
    local selected
    selected=$(echo "$packages" | ui_fzf_select \
        "Search packages (TAB for multi-select)" \
        "$aur_helper -Si {1} 2>/dev/null || echo 'No info available'" \
        "true")

    if [[ -z "$selected" ]]; then
        ui_warning "Cancelled"
        return 0
    fi

    # Count selected packages
    local count
    count=$(echo "$selected" | wc -l)
    ui_success "Selected $count package(s)"
    echo ""

    # Ask which module to add to
    ui_step "Select target module for packages"

    local module
    module=$(_select_module_interactive "Add packages to which module?")

    if [[ -z "$module" ]]; then
        ui_warning "Cancelled"
        return 0
    fi

    ui_step "Adding packages to module: $module"

    # Add each selected package to module
    local added=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue

        # Add to packages.yaml
        yq eval --arg mod "$module" --arg pkg "$pkg" '.packages.modules[$mod].packages += [$pkg]' -i "$PACKAGES_FILE"
        ui_info "  • Added: $pkg"
        ((added++))
    done <<< "$selected"

    echo ""
    ui_success "Added $added package(s) to module: $module"
    ui_info "Run 'package-manager sync' to install packages"
}

# Helper: Interactive module selection
_select_module_interactive() {
    local prompt="${1:-Select module}"

    # Get all modules with descriptions
    local -a fzf_input=()
    while IFS= read -r module; do
        local desc
        local pkg_count
        local enabled
        desc=$(yq eval --arg mod "$module" '.packages.modules[$mod].description' "$PACKAGES_FILE" 2>/dev/null)
        pkg_count=$(yq eval --arg mod "$module" '.packages.modules[$mod].packages | length' "$PACKAGES_FILE" 2>/dev/null)
        enabled=$(yq eval --arg mod "$module" '.packages.modules[$mod].enabled' "$PACKAGES_FILE" 2>/dev/null)

        local status="[disabled]"
        [[ "$enabled" == "true" ]] && status="[enabled]"

        local line
        printf -v line "%-20s | %-50s | (%2d pkgs) | %s" "$module" "$desc" "$pkg_count" "$status"
        fzf_input+=("$line")
    done < <(_get_modules)

    # fzf selection (single module)
    local selected
    selected=$(printf "%s\n" "${fzf_input[@]}" | \
        fzf --height=50% \
            --border=rounded \
            --prompt="$prompt: " \
            --header="ENTER: confirm | ESC: cancel" \
            --preview="yq eval '.packages.modules.{1}' '$PACKAGES_FILE' 2>/dev/null" \
            --preview-window=right:60%:wrap)

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Extract module name (first column)
    echo "$selected" | awk '{print $1}'
}
