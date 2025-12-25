#!/usr/bin/env bash

# Script: cmd-merge.sh
# Purpose: Merge unmanaged packages into modules
# Requirements: yq, pacman, jaq

# =============================================================================
# MODULE METADATA BATCHING
# =============================================================================

# Load all module metadata in a single yq call for performance
# Populates MODULE_DESCRIPTIONS, MODULE_PKG_COUNTS, MODULE_ENABLED arrays
_load_module_metadata() {
    local packages_file="$1"

    # Single yq call extracting all module metadata as JSON (Optimization 2)
    local metadata_json
    metadata_json=$(yq eval '.packages.modules | to_entries | map({
        "name": .key,
        "description": .value.description // "",
        "pkg_count": .value.packages | length,
        "enabled": .value.enabled // true
    })' "$packages_file" -o=json 2>/dev/null)

    if [[ -z "$metadata_json" || "$metadata_json" == "null" ]]; then
        return 1
    fi

    # Parse JSON into associative arrays using jaq
    local module_count
    module_count=$(echo "$metadata_json" | jaq 'length' 2>/dev/null)

    if [[ -z "$module_count" || "$module_count" == "0" ]]; then
        return 1
    fi

    for ((i=0; i<module_count; i++)); do
        local name desc pkg_count enabled
        name=$(echo "$metadata_json" | jaq -r ".[$i].name" 2>/dev/null)
        desc=$(echo "$metadata_json" | jaq -r ".[$i].description" 2>/dev/null)
        pkg_count=$(echo "$metadata_json" | jaq -r ".[$i].pkg_count" 2>/dev/null)
        enabled=$(echo "$metadata_json" | jaq -r ".[$i].enabled" 2>/dev/null)

        [[ -n "$name" ]] && MODULE_DESCRIPTIONS["$name"]="$desc"
        [[ -n "$name" ]] && MODULE_PKG_COUNTS["$name"]="$pkg_count"
        [[ -n "$name" ]] && MODULE_ENABLED["$name"]="$enabled"
    done

    return 0
}

# =============================================================================
# PACKAGE ADDITION BATCHING
# =============================================================================

# Add multiple packages to a module in a single atomic operation
# Usage: _add_packages_to_module_batch <target_module> <packages_file> <pkg1> <pkg2> ...
_add_packages_to_module_batch() {
    local target_module="$1"
    local packages_file="$2"
    shift 2
    local packages_to_add=("$@")

    if [[ ${#packages_to_add[@]} -eq 0 ]]; then
        return 0
    fi

    # Build JSON array of packages (Optimization 3)
    local packages_json
    packages_json=$(printf '%s\n' "${packages_to_add[@]}" | jaq -R . | jaq -s . 2>/dev/null)

    if [[ -z "$packages_json" || "$packages_json" == "null" ]]; then
        ui_error "Failed to build package JSON array"
        return 1
    fi

    # Single atomic update with temp file
    local temp_file="${packages_file}.tmp.$$"
    if ! yq eval ".packages.modules[\"$target_module\"].packages += $packages_json" \
            "$packages_file" > "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        ui_error "Failed to update packages file"
        return 1
    fi

    # Atomic rename (POSIX guarantee)
    if ! mv "$temp_file" "$packages_file" 2>/dev/null; then
        rm -f "$temp_file"
        ui_error "Failed to write packages file"
        return 1
    fi

    return 0
}

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

    ui_title "$ICON_PACKAGE Merge Unmanaged Packages"
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
        [[ -n "$pkg" ]] && declared_set[$pkg]=1
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

    # Load module metadata once for performance (Optimization 2)
    declare -A MODULE_DESCRIPTIONS MODULE_PKG_COUNTS MODULE_ENABLED
    if ! _load_module_metadata "$PACKAGES_FILE"; then
        ui_error "Failed to load module metadata"
        return 1
    fi

    # Module selection with fzf if available
    local selected_module
    if command -v fzf >/dev/null 2>&1; then
        # fzf-powered module selection with preview (using cached metadata)
        local -a fzf_input=()
        while IFS= read -r module; do
            [[ -z "$module" ]] && continue

            # Use cached metadata instead of individual yq calls
            local description="${MODULE_DESCRIPTIONS[$module]}"
            local pkg_count="${MODULE_PKG_COUNTS[$module]}"
            local enabled="${MODULE_ENABLED[$module]}"

            [[ -z "$description" || "$description" == "null" ]] && description="No description"
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

        # Display module options (using cached metadata)
        ui_info "Available modules:"
        echo ""
        local i=1
        for module in "${module_list[@]}"; do
            # Use cached metadata instead of individual yq call
            local description="${MODULE_DESCRIPTIONS[$module]}"
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

    # Add all packages in a single batch operation (Optimization 3)
    if ! _add_packages_to_module_batch "$selected_module" "$PACKAGES_FILE" "${unmanaged[@]}"; then
        ui_error "Failed to add packages to module '$selected_module'"
        return 1
    fi

    echo ""
    ui_success "Added ${#unmanaged[@]} packages to module '$selected_module'"
    ui_info "Run 'package-manager sync' to reconcile system state"
}
