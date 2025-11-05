#!/usr/bin/env bash

# Package Manager - Sophisticated strategy-aware package management
# Purpose: Strategy-based package installation with fallback chains
# Requirements: Arch Linux, pacman, yay, gum (UI library)

# Source the UI library
if [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
else
    echo "Error: UI library not found at $UI_LIB" >&2
    exit 1
fi

# Global configuration
PACKAGES_FILE="$HOME/.local/share/chezmoi/.chezmoidata/packages.yaml"

# =============================================================================
# STRATEGY INSTALLATION FUNCTIONS
# =============================================================================

_try_pacman_install() {
    local packages=("$@")
    _execute_or_dry_run "Trying pacman installation: ${packages[*]}" \
        "sudo pacman -S --noconfirm --needed ${packages[*]}"
}

_try_yay_bin_install() {
    local packages=("$@")

    if ! command -v yay >/dev/null 2>&1; then
        _log_verbose "yay not available, skipping binary AUR installation"
        return 1
    fi

    _execute_or_dry_run "Trying yay binary installation: ${packages[*]}" \
        "yay -S --noconfirm --needed ${packages[*]}"
}

_try_yay_source_install() {
    local packages=("$@")

    if ! command -v yay >/dev/null 2>&1; then
        _log_verbose "yay not available, skipping source AUR installation"
        return 1
    fi

    _execute_or_dry_run "Trying yay source installation: ${packages[*]}" \
        "yay -S --noconfirm --needed --builddir /tmp ${packages[*]}"
}

# =============================================================================
# REMOVAL FUNCTIONS
# =============================================================================

_try_remove_packages() {
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        _log_verbose "No packages to remove"
        return 0
    fi

    if command -v yay >/dev/null 2>&1; then
        _execute_or_dry_run "Removing packages: ${packages[*]}" \
            "yay -R --noconfirm ${packages[*]}"
    else
        _execute_or_dry_run "Removing packages: ${packages[*]}" \
            "sudo pacman -R --noconfirm ${packages[*]}"
    fi
}

# =============================================================================
# STRATEGY PROCESSING FUNCTIONS
# =============================================================================

_get_strategy_for_category() {
    local category="$1"
    _check_yq_dependency || return 1

    # Get strategy from packages.yaml, default to "default_strategy" if not specified
    local strategy
    strategy=$(yq eval ".packages.install.arch.packages.${category}.strategy // \"default_strategy\"" "$PACKAGES_FILE" 2>/dev/null)

    if [[ "$strategy" == "null" || -z "$strategy" ]]; then
        strategy="default_strategy"
    fi

    echo "$strategy"
}

_get_strategy_methods() {
    local strategy="$1"
    _check_yq_dependency || return 1

    # Get the array of methods for this strategy
    yq eval ".packages.install.arch.strategies.${strategy} | .[]" "$PACKAGES_FILE" 2>/dev/null
}

_install_packages_with_strategy() {
    local category="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        _log_verbose "No packages specified for category: $category"
        return 0
    fi

    # Get strategy for this category
    local strategy
    if ! strategy=$(_get_strategy_for_category "$category"); then
        return 1
    fi

    _log_verbose "Using strategy '$strategy' for category '$category'"

    # Get methods for this strategy
    local methods=()
    while IFS= read -r method; do
        methods+=("$method")
    done < <(_get_strategy_methods "$strategy")

    if [[ ${#methods[@]} -eq 0 ]]; then
        ui_error "No methods found for strategy: $strategy"
        return 1
    fi

    # Try each method in the strategy chain
    for method in "${methods[@]}"; do
        _log_verbose "Trying method: $method"

        case "$method" in
            "pacman")
                if _try_pacman_install "${packages[@]}"; then
                    _log_verbose "Successfully installed with pacman: ${packages[*]}"
                    return 0
                fi
                ;;
            "yay_bin")
                if _try_yay_bin_install "${packages[@]}"; then
                    _log_verbose "Successfully installed with yay (binary): ${packages[*]}"
                    return 0
                fi
                ;;
            "yay_source")
                if _try_yay_source_install "${packages[@]}"; then
                    _log_verbose "Successfully installed with yay (source): ${packages[*]}"
                    return 0
                fi
                ;;
            *)
                ui_warning "Unknown installation method: $method"
                ;;
        esac
    done

    # All methods failed
    ui_error "Failed to install packages with strategy '$strategy': ${packages[*]}"
    return 1
}

# =============================================================================
# PACKAGE CATEGORY FUNCTIONS
# =============================================================================

_get_package_categories() {
    _check_yq_dependency || return 1
    yq eval '.packages.install.arch.packages | keys | .[]' "$PACKAGES_FILE" 2>/dev/null
}

_get_packages_for_category() {
    local category="$1"
    _check_yq_dependency || return 1
    yq eval ".packages.install.arch.packages.${category}.list | .[]" "$PACKAGES_FILE" 2>/dev/null
}

_install_category() {
    local category="$1"

    # Get packages for this category
    local packages=()
    while IFS= read -r package; do
        [[ -n "$package" && "$package" != "null" ]] && packages+=("$package")
    done < <(_get_packages_for_category "$category")

    if [[ ${#packages[@]} -eq 0 ]]; then
        ui_warning "No packages found in category: $category"
        return 0
    fi

    ui_info "Installing category '$category' (${#packages[@]} packages)"
    _log_verbose "Packages: ${packages[*]}"

    _install_packages_with_strategy "$category" "${packages[@]}"
}

_remove_category() {
    local category="$1"

    # Get packages for this category
    local packages=()
    while IFS= read -r package; do
        [[ -n "$package" && "$package" != "null" ]] && packages+=("$package")
    done < <(_get_packages_for_category "$category")

    if [[ ${#packages[@]} -eq 0 ]]; then
        ui_warning "No packages found in category: $category"
        return 0
    fi

    ui_info "Removing category '$category' (${#packages[@]} packages)"
    _log_verbose "Packages: ${packages[*]}"

    _try_remove_packages "${packages[@]}"
}

_install_all_categories() {
    _check_yq_dependency || return 1

    ui_title "📦 Installing All Package Categories"

    local categories=()
    while IFS= read -r category; do
        [[ -n "$category" && "$category" != "null" ]] && categories+=("$category")
    done < <(_get_package_categories)

    if [[ ${#categories[@]} -eq 0 ]]; then
        ui_error "No package categories found"
        return 1
    fi

    ui_info "Found ${#categories[@]} categories to install"
    _log_verbose "Categories: ${categories[*]}"

    local failed_categories=()
    for category in "${categories[@]}"; do
        ui_subtitle "📋 Installing: $category"

        if ! _install_category "$category"; then
            failed_categories+=("$category")
            ui_error "Failed to install category: $category"
        else
            ui_success "Successfully installed category: $category"
        fi
        ui_spacer
    done

    # Summary
    if [[ ${#failed_categories[@]} -eq 0 ]]; then
        ui_success "All categories installed successfully!"
        return 0
    else
        ui_error "Some categories failed to install: ${failed_categories[*]}"
        return 1
    fi
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

_log_verbose() {
    local message="$1"
    [[ "$VERBOSE" == "true" ]] && ui_info "$message"
    return 0
}

_execute_or_dry_run() {
    local description="$1"
    local command="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        ui_info "[DRY-RUN] Would run: $command"
        return 0
    fi

    _log_verbose "$description"
    eval "$command" 2>/dev/null
}

_check_yq_dependency() {
    if ! command -v yq >/dev/null 2>&1; then
        ui_error "yq is required for strategy processing. Install with: pacman -S yq"
        return 1
    fi
    return 0
}

_parse_options() {
    while [[ $# -gt 0 ]] && [[ "$1" == --* ]]; do
        case $1 in
            --verbose|-v)
                export VERBOSE="true"
                shift
                ;;
            --dry-run|-n)
                export DRY_RUN="true"
                shift
                ;;
            --brief|-b)
                export BRIEF="true"
                shift
                ;;
            --*)
                ui_error "Unknown option: $1"
                show_usage
                return 1
                ;;
        esac
    done
    # Return remaining arguments
    echo "$@"
    return 0
}

show_usage() {
    echo "Usage: package-manager [options] <command> [args] [options]"
    echo ""
    echo "Commands:"
    echo "  install-all          Install all package categories"
    echo "  install <category>   Install specific category"
    echo "  remove <category>    Remove all packages in category"
    echo "  remove-package <pkg> Remove specific package"
    echo "  sync                 Declarative sync (install missing + remove extras)"
    echo "  update-strategy      Update packages using strategy system"
    echo "  health               Check essential dependencies"
    echo ""
    echo "Options (can appear before or after command):"
    echo "  --verbose, -v        Enable verbose output"
    echo "  --dry-run, -n        Show what would be done"
    echo "  --brief, -b          Brief output (for automation)"
    echo "  --help, -h           Show this help"
    echo ""
    echo "Examples:"
    echo "  package-manager health --brief"
    echo "  package-manager --verbose install fonts"
    echo "  package-manager install-all --dry-run"
    echo "  package-manager remove work_software"
    echo "  package-manager remove-package spotify"
    echo "  package-manager sync"
    return 0
}




check_health() {
    if [[ "$BRIEF" != "true" ]]; then
        ui_title "🩺 Package System Health Check"
    fi

    local issues=0

    # Check essential dependencies
    if command -v yq >/dev/null 2>&1; then
        [[ "$BRIEF" != "true" ]] && ui_success "yq: Available"
    else
        ui_error "yq: Missing (required for strategy processing)"
        ((issues++))
    fi

    if command -v pacman >/dev/null 2>&1; then
        [[ "$BRIEF" != "true" ]] && ui_success "pacman: Available"
    else
        ui_error "pacman: Missing"
        ((issues++))
    fi

    if command -v yay >/dev/null 2>&1; then
        [[ "$BRIEF" != "true" ]] && ui_success "yay: Available"
    else
        [[ "$BRIEF" != "true" ]] && ui_warning "yay: Missing (AUR packages will be skipped)"
    fi

    # Check packages file
    if [[ -f "$PACKAGES_FILE" ]]; then
        [[ "$BRIEF" != "true" ]] && ui_success "packages.yaml: Found"

        # Validate YAML syntax
        if command -v yq >/dev/null 2>&1 && yq eval '.' "$PACKAGES_FILE" >/dev/null 2>&1; then
            [[ "$BRIEF" != "true" ]] && ui_success "packages.yaml: Valid syntax"
        else
            ui_error "packages.yaml: Invalid syntax"
            ((issues++))
        fi
    else
        ui_error "packages.yaml: Not found at $PACKAGES_FILE"
        ((issues++))
    fi

    # Summary
    if [[ "$BRIEF" == "true" ]]; then
        if [[ $issues -eq 0 ]]; then
            ui_success "Package system health: OK"
            return 0
        else
            ui_error "Package system health: $issues issues found"
            return 1
        fi
    else
        if [[ $issues -eq 0 ]]; then
            ui_success "Essential dependencies available" --before 1
            return 0
        else
            ui_error "Missing essential dependencies" --before 1
            return 1
        fi
    fi
}

update_strategy() {
    if [[ "$BRIEF" != "true" ]]; then
        ui_title "🔄 Strategy-Aware Package Update"
        ui_info "This will update packages using the same strategy system as installation"
        ui_spacer
    fi

    _check_yq_dependency || return 1

    # Run standard updates
    if command -v yay >/dev/null 2>&1; then
        _log_verbose "Running standard package updates..."
        _execute_or_dry_run "Running yay update" "yay -Syu --noconfirm" || {
            ui_error "Standard package update failed"
            return 1
        }
    else
        _log_verbose "Running pacman updates..."
        _execute_or_dry_run "Running pacman update" "sudo pacman -Syu --noconfirm" || {
            ui_error "Pacman update failed"
            return 1
        }
    fi

    # Validate strategy health
    _log_verbose "Validating package strategy health..."

    if check_health; then
        [[ "$BRIEF" != "true" ]] && ui_success "Strategy-aware update completed successfully"
        return 0
    else
        ui_warning "Package update completed but strategy validation found issues"
        return 1
    fi
}

sync_packages() {
    if [[ "$BRIEF" != "true" ]]; then
        ui_title "🔄 Declarative Package Sync"
        ui_info "Syncing installed packages with packages.yaml configuration"
        ui_spacer
    fi

    _check_yq_dependency || return 1

    # State file location
    local state_file="$HOME/.local/state/chezmoi/package-manager-state.txt"
    mkdir -p "$(dirname "$state_file")"

    # Build list of desired packages from config
    ui_info "Building desired package list from configuration..."
    local desired_packages=()
    local categories=()

    while IFS= read -r category; do
        [[ -n "$category" && "$category" != "null" ]] && categories+=("$category")
    done < <(_get_package_categories)

    for category in "${categories[@]}"; do
        while IFS= read -r package; do
            [[ -n "$package" && "$package" != "null" ]] && desired_packages+=("$package")
        done < <(_get_packages_for_category "$category")
    done

    _log_verbose "Desired packages: ${desired_packages[*]}"

    # Install missing packages
    ui_subtitle "📦 Installing missing packages..."
    if ! _install_all_categories; then
        ui_error "Failed to install packages"
        return 1
    fi

    # Get previously tracked packages
    local previous_packages=()
    if [[ -f "$state_file" ]]; then
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && previous_packages+=("$pkg")
        done < "$state_file"
    fi

    # Find packages to remove
    local packages_to_remove=()
    for pkg in "${previous_packages[@]}"; do
        local found=false
        for desired in "${desired_packages[@]}"; do
            if [[ "$pkg" == "$desired" ]]; then
                found=true
                break
            fi
        done

        if [[ "$found" == "false" ]]; then
            # Check if package is actually installed
            if pacman -Qi "$pkg" >/dev/null 2>&1; then
                packages_to_remove+=("$pkg")
            fi
        fi
    done

    # Remove packages no longer in config
    if [[ ${#packages_to_remove[@]} -gt 0 ]]; then
        ui_subtitle "🗑️  Removing packages no longer in config..."
        ui_info "Packages to remove: ${packages_to_remove[*]}"
        _try_remove_packages "${packages_to_remove[@]}"
    else
        ui_info "No packages to remove"
    fi

    # Update state file
    printf "%s\n" "${desired_packages[@]}" > "$state_file"

    if [[ "$BRIEF" != "true" ]]; then
        ui_success "Package sync completed successfully" --before 1
    else
        ui_success "Package sync completed"
    fi
}


# =============================================================================
# MAIN FUNCTION AND ARGUMENT PARSING
# =============================================================================

package-manager() {
    # Initialize variables (can be overridden by environment or command line)
    VERBOSE=${PACKAGE_MANAGER_VERBOSE:-false}
    DRY_RUN=${PACKAGE_MANAGER_DRY_RUN:-false}
    BRIEF=${PACKAGE_MANAGER_BRIEF:-false}

    # Parse global options that can appear before command
    while [[ $# -gt 0 ]] && [[ "$1" == --* ]]; do
        case $1 in
            --help|-h)
                show_usage
                return 0
                ;;
            --verbose|-v)
                export VERBOSE="true"
                shift
                ;;
            --dry-run|-n)
                export DRY_RUN="true"
                shift
                ;;
            --brief|-b)
                export BRIEF="true"
                shift
                ;;
            --*)
                ui_error "Unknown option: $1"
                show_usage
                return 1
                ;;
        esac
    done

    # Handle commands
    if [[ $# -eq 0 ]] || [[ "$1" == --* ]]; then
        ui_error "No command provided"
        show_usage
        return 1
    fi

    local command="$1"
    shift

    # Parse options that can appear after command (for commands that don't take arguments)
    if [[ "$command" != "install" && "$command" != "remove" && "$command" != "remove-package" ]]; then
        while [[ $# -gt 0 ]] && [[ "$1" == --* ]]; do
            case $1 in
                --verbose|-v)
                    export VERBOSE="true"
                    shift
                    ;;
                --dry-run|-n)
                    export DRY_RUN="true"
                    shift
                    ;;
                --brief|-b)
                    export BRIEF="true"
                    shift
                    ;;
                --*)
                    ui_error "Unknown option: $1"
                    show_usage
                    return 1
                    ;;
            esac
        done
    fi

    case "$command" in
        "install-all")
            _install_all_categories
            ;;
        "install")
            if [[ $# -eq 0 ]]; then
                ui_error "Category name required for install command"
                return 1
            fi
            local category="$1"
            shift
            # Parse any remaining options after category using helper function
            _parse_options "$@" >/dev/null || return 1
            _install_category "$category"
            ;;
        "remove")
            if [[ $# -eq 0 ]]; then
                ui_error "Category name required for remove command"
                return 1
            fi
            local category="$1"
            shift
            # Parse any remaining options after category using helper function
            _parse_options "$@" >/dev/null || return 1
            _remove_category "$category"
            ;;
        "remove-package")
            if [[ $# -eq 0 ]]; then
                ui_error "Package name required for remove-package command"
                return 1
            fi
            local package="$1"
            shift
            # Parse any remaining options after package using helper function
            _parse_options "$@" >/dev/null || return 1
            _try_remove_packages "$package"
            ;;
        "sync")
            sync_packages
            ;;
        "update-strategy")
            update_strategy
            ;;
        "health")
            check_health
            ;;
        *)
            ui_error "Unknown command: $command"
            show_usage
            return 1
            ;;
    esac
}

# Execute the function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    package-manager "$@"
fi