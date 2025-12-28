#!/usr/bin/env bash

# Script: manager-interface.sh
# Purpose: Package Manager Abstraction Layer
# Provides unified interface for multiple package managers (pacman, flatpak, homebrew, nix)

# =============================================================================
# PACKAGE MANAGER DETECTION
# =============================================================================

_detect_package_manager() {
    # Detect package manager type from package name
    # Args: package_name
    # Returns: manager type (pacman|flatpak|homebrew|nix)
    local package="$1"

    # Flatpak prefix
    if [[ "$package" == flatpak:* ]]; then
        echo "flatpak"
        return 0
    fi

    # Homebrew prefix (future)
    if [[ "$package" == brew:* ]]; then
        echo "homebrew"
        return 0
    fi

    # Nix prefix (future)
    if [[ "$package" == nix:* ]]; then
        echo "nix"
        return 0
    fi

    # Default to pacman (Arch)
    echo "pacman"
}

# =============================================================================
# UNIFIED PACKAGE MANAGER OPERATIONS
# =============================================================================

_pm_install() {
    # Install a package using the appropriate package manager
    # Args: manager_type package_name [version]
    # Returns: 0 on success, 1 on failure
    local manager_type="$1"
    local package="$2"
    local version="${3:-}"

    case "$manager_type" in
        pacman)
            _pm_pacman_install "$package" "$version"
            ;;
        flatpak)
            _pm_flatpak_install "$package"
            ;;
        homebrew)
            _pm_homebrew_install "$package" "$version"
            ;;
        nix)
            _pm_nix_install "$package" "$version"
            ;;
        *)
            ui_error "Unknown package manager: $manager_type"
            return 1
            ;;
    esac
}

_pm_remove() {
    # Remove a package using the appropriate package manager
    # Args: manager_type package_name
    # Returns: 0 on success, 1 on failure
    local manager_type="$1"
    local package="$2"

    case "$manager_type" in
        pacman)
            _pm_pacman_remove "$package"
            ;;
        flatpak)
            _pm_flatpak_remove "$package"
            ;;
        homebrew)
            _pm_homebrew_remove "$package"
            ;;
        nix)
            _pm_nix_remove "$package"
            ;;
        *)
            ui_error "Unknown package manager: $manager_type"
            return 1
            ;;
    esac
}

_pm_query_version() {
    # Query installed version of a package
    # Args: manager_type package_name
    # Returns: version string on stdout, 1 on failure
    local manager_type="$1"
    local package="$2"

    case "$manager_type" in
        pacman)
            _pm_pacman_query_version "$package"
            ;;
        flatpak)
            _pm_flatpak_query_version "$package"
            ;;
        homebrew)
            _pm_homebrew_query_version "$package"
            ;;
        nix)
            _pm_nix_query_version "$package"
            ;;
        *)
            return 1
            ;;
    esac
}

_pm_is_installed() {
    # Check if a package is installed
    # Args: manager_type package_name
    # Returns: 0 if installed, 1 if not
    local manager_type="$1"
    local package="$2"

    case "$manager_type" in
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
        flatpak)
            local flatpak_id="${package#flatpak:}"
            flatpak list --app --columns=application 2>/dev/null | grep -q "^${flatpak_id}$"
            ;;
        homebrew)
            brew list "$package" &>/dev/null
            ;;
        nix)
            nix-env -q "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# PACMAN IMPLEMENTATION
# =============================================================================

_pm_pacman_install() {
    # Install package via pacman/paru
    # Args: package_name [version]
    local package="$1"
    local version="$2"

    if [[ -n "$version" ]]; then
        paru -S --noconfirm --needed "${package}=${version}"
    else
        paru -S --noconfirm --needed "$package"
    fi
}

_pm_pacman_remove() {
    # Remove package via pacman/paru
    # Args: package_name
    local package="$1"
    paru -R --noconfirm "$package"
}

_pm_pacman_query_version() {
    # Query installed pacman package version
    # Args: package_name
    local package="$1"
    pacman -Q "$package" 2>/dev/null | awk '{print $2}'
}

# =============================================================================
# FLATPAK IMPLEMENTATION
# =============================================================================

_pm_flatpak_install() {
    # Install package via flatpak
    # Args: package_name (with flatpak: prefix)
    local package="$1"
    # Remove flatpak: prefix
    package="${package#flatpak:}"
    flatpak install -y --user flathub "$package"
}

_pm_flatpak_remove() {
    # Remove package via flatpak
    # Args: package_name (with flatpak: prefix)
    local package="$1"
    package="${package#flatpak:}"
    flatpak uninstall -y --user "$package"
}

_pm_flatpak_query_version() {
    # Query installed flatpak package version
    # Args: package_name (with flatpak: prefix)
    local package="$1"
    package="${package#flatpak:}"
    flatpak list --app --columns=application,version 2>/dev/null | \
        grep "^${package}" | awk '{print $2}'
}

# =============================================================================
# HOMEBREW IMPLEMENTATION (Placeholder for Future Support)
# =============================================================================

_pm_homebrew_install() {
    # Install package via homebrew (not yet implemented)
    # Args: package_name [version]
    local package="$1"
    local version="$2"

    ui_error "Homebrew support not yet implemented"
    ui_info "To add support: implement _pm_homebrew_install() in manager-interface.sh"
    return 1
}

_pm_homebrew_remove() {
    # Remove package via homebrew (not yet implemented)
    # Args: package_name
    ui_error "Homebrew support not yet implemented"
    return 1
}

_pm_homebrew_query_version() {
    # Query homebrew package version (not yet implemented)
    # Args: package_name
    ui_error "Homebrew support not yet implemented"
    return 1
}

# =============================================================================
# NIX IMPLEMENTATION (Placeholder for Future Support)
# =============================================================================

_pm_nix_install() {
    # Install package via nix (not yet implemented)
    # Args: package_name [version]
    local package="$1"
    local version="$2"

    ui_error "Nix support not yet implemented"
    ui_info "To add support: implement _pm_nix_install() in manager-interface.sh"
    return 1
}

_pm_nix_remove() {
    # Remove package via nix (not yet implemented)
    # Args: package_name
    ui_error "Nix support not yet implemented"
    return 1
}

_pm_nix_query_version() {
    # Query nix package version (not yet implemented)
    # Args: package_name
    ui_error "Nix support not yet implemented"
    return 1
}
