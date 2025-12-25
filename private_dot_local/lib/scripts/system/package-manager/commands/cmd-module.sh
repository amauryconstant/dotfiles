#!/usr/bin/env bash

# Script: cmd-module.sh
# Purpose: Module management commands
# Requirements: yq

cmd_module_list() {
    _check_yq_dependency || return 1

    ui_title "$ICON_PACKAGE Package Modules"
    echo ""

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        local enabled
        local description
        local pkg_count
        enabled=$(MOD="$module" yq eval '.packages.modules[env(MOD)].enabled' "$PACKAGES_FILE" 2>/dev/null)
        description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE" 2>/dev/null)
        pkg_count=$(MOD="$module" yq eval '.packages.modules[env(MOD)].packages | length' "$PACKAGES_FILE" 2>/dev/null)

        if [[ "$enabled" == "true" ]]; then
            ui_success "  $ICON_CHECK ${module} (${pkg_count} packages) - ${description}"
        else
            ui_info "  $ICON_ERROR ${module} (${pkg_count} packages) - ${description}" | ui_color gray
        fi
    done < <(_get_modules)
}

cmd_module_enable_interactive() {
    _check_yq_dependency || return 1

    ui_title "$ICON_PACKAGE Enable Modules"
    echo ""

    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        _module_enable_interactive_fallback
        return $?
    fi

    # Collect disabled modules with formatted display
    local -a fzf_input=()
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        if ! _is_module_enabled "$module"; then
            local description
            description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE" 2>/dev/null)
            [[ -z "$description" || "$description" == "null" ]] && description="No description"

            local pkg_count
            pkg_count=$(MOD="$module" yq eval '.packages.modules[env(MOD)].packages | length' "$PACKAGES_FILE" 2>/dev/null)

            # Format: "module_name | description | (N packages) | [disabled]"
            printf -v line "%-20s | %-50s | (%2d packages) | [disabled]" "$module" "$description" "$pkg_count"
            fzf_input+=("$line")
        fi
    done < <(_get_modules)

    if [[ ${#fzf_input[@]} -eq 0 ]]; then
        ui_warning "All modules are already enabled"
        return 0
    fi

    # fzf selection with preview
    local selected
    selected=$(printf "%s\n" "${fzf_input[@]}" | \
        fzf --multi \
            --height=80% \
            --border=rounded \
            --prompt="Select modules to enable (TAB to multi-select): " \
            --header="ENTER: confirm | ESC: cancel | TAB: multi-select" \
            --preview="yq eval '.packages.modules.{1}' '$PACKAGES_FILE' 2>/dev/null || echo 'No details available'" \
            --preview-window=right:60%:wrap)

    if [[ -z "$selected" ]]; then
        ui_warning "Cancelled"
        return 0
    fi

    # Extract module names and enable them
    local enabled_count=0
    while IFS= read -r line; do
        local module=$(echo "$line" | awk '{print $1}')
        echo ""
        if cmd_module_enable "$module"; then
            ((enabled_count++))
        fi
    done <<< "$selected"

    if [[ $enabled_count -gt 0 ]]; then
        echo ""
        ui_success "Enabled $enabled_count module(s)"
        ui_info "Run 'package-manager sync' to install packages"
    fi
}

# Fallback to numbered menu when fzf not available
_module_enable_interactive_fallback() {
    # Collect disabled modules
    local -a module_names=()
    local -a module_descriptions=()

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        if ! _is_module_enabled "$module"; then
            module_names+=("$module")

            local description
            description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE" 2>/dev/null)
            [[ -z "$description" || "$description" == "null" ]] && description="No description"
            module_descriptions+=("$description")
        fi
    done < <(_get_modules)

    if [[ ${#module_names[@]} -eq 0 ]]; then
        ui_warning "All modules are already enabled"
        return 0
    fi

    ui_info "Select modules to enable (comma or space separated):"
    echo ""

    local i=1
    for idx in "${!module_names[@]}"; do
        ui_info "  ${i}) ${module_names[$idx]}"
        ui_info "     ${module_descriptions[$idx]}"
        ui_spacer
        ((i++))
    done

    read -p "Selection (or 'q' to quit): " selection

    if [[ "$selection" == "q" ]] || [[ -z "$selection" ]]; then
        ui_warning "Cancelled"
        return 0
    fi

    # Parse selection (handle comma and space separated)
    selection="${selection//,/ }"
    local -a selected_numbers
    IFS=' ' read -ra selected_numbers <<< "$selection"

    local enabled_count=0
    for num in "${selected_numbers[@]}"; do
        # Validate number
        if ! [[ "$num" =~ ^[0-9]+$ ]]; then
            ui_error "Invalid selection: $num"
            continue
        fi

        local idx=$((num - 1))
        if [[ $idx -lt 0 ]] || [[ $idx -ge ${#module_names[@]} ]]; then
            ui_error "Invalid selection: $num"
            continue
        fi

        local module_to_enable="${module_names[$idx]}"
        echo ""
        cmd_module_enable "$module_to_enable"
        ((enabled_count++))
    done

    if [[ $enabled_count -gt 0 ]]; then
        echo ""
        ui_success "Enabled $enabled_count module(s)"
        ui_info "Run 'package-manager sync' to install packages"
    fi
}

cmd_module_enable() {
    local module="$1"
    _check_yq_dependency || return 1

    if [[ -z "$module" ]]; then
        ui_error "Module name required"
        return 1
    fi

    # Check if module exists
    if ! _with_context "Checking if module '$module' exists in packages.yaml" \
         MOD="$module" yq eval '.packages.modules | has(env(MOD))' "$PACKAGES_FILE" | grep -q "true"; then
        ui_error "Module '$module' not found"
        return 1
    fi

    # Check if already enabled
    if _is_module_enabled "$module"; then
        ui_warning "Module '$module' is already enabled"
        return 0
    fi

    # Check for conflicts
    local conflicts=$(_get_module_conflicts "$module")
    if [[ -n "$conflicts" ]]; then
        while IFS= read -r conflict; do
            [[ -z "$conflict" ]] && continue

            if _is_module_enabled "$conflict"; then
                ui_warning "Module '$module' conflicts with enabled module '$conflict'"

                if ui_confirm "Disable '$conflict' and enable '$module'?"; then
                    # Disable conflicting module
                    MOD="$conflict" yq eval '.packages.modules[env(MOD)].enabled = false' -i "$PACKAGES_FILE"
                    _invalidate_module_cache  # Invalidate cache after modification
                    ui_success "Disabled '$conflict'"
                else
                    ui_warning "Cancelled"
                    return 0
                fi
            fi
        done <<< "$conflicts"
    fi

    # Enable module
    MOD="$module" yq eval '.packages.modules[env(MOD)].enabled = true' -i "$PACKAGES_FILE"
    _invalidate_module_cache  # Invalidate cache after modification
    ui_success "Module '$module' enabled"
    ui_info "Run 'package-manager sync' to install packages"
}

cmd_module_disable_interactive() {
    _check_yq_dependency || return 1

    ui_title "$ICON_PACKAGE Disable Modules"
    echo ""

    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        _module_disable_interactive_fallback
        return $?
    fi

    # Collect enabled modules with formatted display
    local -a fzf_input=()
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        local description
        local pkg_count
        description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE" 2>/dev/null)
        [[ -z "$description" || "$description" == "null" ]] && description="No description"

        pkg_count=$(MOD="$module" yq eval '.packages.modules[env(MOD)].packages | length' "$PACKAGES_FILE" 2>/dev/null)

        # Format: "module_name | description | (N packages) | [enabled]"
        printf -v line "%-20s | %-50s | (%2d packages) | [enabled]" "$module" "$description" "$pkg_count"
        fzf_input+=("$line")
    done < <(_get_enabled_modules)

    if [[ ${#fzf_input[@]} -eq 0 ]]; then
        ui_warning "No modules are currently enabled"
        return 0
    fi

    # fzf selection with preview
    local selected
    selected=$(printf "%s\n" "${fzf_input[@]}" | \
        fzf --multi \
            --height=80% \
            --border=rounded \
            --prompt="Select modules to disable (TAB to multi-select): " \
            --header="ENTER: confirm | ESC: cancel | TAB: multi-select" \
            --preview="yq eval '.packages.modules.{1}' '$PACKAGES_FILE' 2>/dev/null || echo 'No details available'" \
            --preview-window=right:60%:wrap)

    if [[ -z "$selected" ]]; then
        ui_warning "Cancelled"
        return 0
    fi

    # Extract module names and disable them
    local disabled_count=0
    while IFS= read -r line; do
        local module=$(echo "$line" | awk '{print $1}')
        echo ""
        if cmd_module_disable "$module"; then
            ((disabled_count++))
        fi
    done <<< "$selected"

    if [[ $disabled_count -gt 0 ]]; then
        echo ""
        ui_success "Disabled $disabled_count module(s)"
        ui_info "Run 'package-manager sync --prune' to remove packages"
    fi
}

# Fallback to numbered menu when fzf not available
_module_disable_interactive_fallback() {
    # Collect enabled modules
    local -a module_names=()
    local -a module_descriptions=()

    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        module_names+=("$module")

        local description
        description=$(MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE" 2>/dev/null)
        [[ -z "$description" || "$description" == "null" ]] && description="No description"
        module_descriptions+=("$description")
    done < <(_get_enabled_modules)

    if [[ ${#module_names[@]} -eq 0 ]]; then
        ui_warning "No modules are currently enabled"
        return 0
    fi

    ui_info "Select modules to disable (comma or space separated):"
    echo ""

    local i=1
    for idx in "${!module_names[@]}"; do
        ui_info "  ${i}) ${module_names[$idx]}"
        ui_info "     ${module_descriptions[$idx]}"
        ui_spacer
        ((i++))
    done

    read -p "Selection (or 'q' to quit): " selection

    if [[ "$selection" == "q" ]] || [[ -z "$selection" ]]; then
        ui_warning "Cancelled"
        return 0
    fi

    # Parse selection (handle comma and space separated)
    selection="${selection//,/ }"
    local -a selected_numbers
    IFS=' ' read -ra selected_numbers <<< "$selection"

    local disabled_count=0
    for num in "${selected_numbers[@]}"; do
        # Validate number
        if ! [[ "$num" =~ ^[0-9]+$ ]]; then
            ui_error "Invalid selection: $num"
            continue
        fi

        local idx=$((num - 1))
        if [[ $idx -lt 0 ]] || [[ $idx -ge ${#module_names[@]} ]]; then
            ui_error "Invalid selection: $num"
            continue
        fi

        local module_to_disable="${module_names[$idx]}"
        echo ""
        cmd_module_disable "$module_to_disable"
        ((disabled_count++))
    done

    if [[ $disabled_count -gt 0 ]]; then
        echo ""
        ui_success "Disabled $disabled_count module(s)"
        ui_info "Run 'package-manager sync --prune' to remove packages"
    fi
}

cmd_module_disable() {
    local module="$1"
    _check_yq_dependency || return 1

    if [[ -z "$module" ]]; then
        ui_error "Module name required"
        return 1
    fi

    # Check if module exists
    if ! _with_context "Checking if module '$module' exists in packages.yaml" \
         yq eval ".packages.modules | has(\"$module\")" "$PACKAGES_FILE" | grep -q "true"; then
        ui_error "Module '$module' not found"
        return 1
    fi

    # Check if enabled
    if ! _is_module_enabled "$module"; then
        ui_warning "Module '$module' is not enabled"
        return 0
    fi

    # Disable module
    MOD="$module" yq eval '.packages.modules[env(MOD)].enabled = false' -i "$PACKAGES_FILE"
    _invalidate_module_cache  # Invalidate cache after modification
    ui_success "Module '$module' disabled"
    ui_info "Run 'package-manager sync --prune' to remove packages"
}
