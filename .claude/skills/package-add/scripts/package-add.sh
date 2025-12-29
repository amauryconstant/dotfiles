#!/usr/bin/env bash

# Script: package-add.sh
# Purpose: Validate and add packages to packages.yaml
# Requirements: yq, jaq, pacman, paru, flatpak

set -euo pipefail

# Configuration
PACKAGES_YAML="${PACKAGES_YAML:-$HOME/.local/share/chezmoi/.chezmoidata/packages.yaml}"
CACHE_DIR="$HOME/.cache/package-add"
CACHE_TTL=86400  # 24 hours

mkdir -p "$CACHE_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helpers
log_info() { echo -e "${GREEN}ℹ️${NC} $*" >&2; }
log_error() { echo -e "${RED}❌${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}⚠️${NC} $*" >&2; }

# Validate Arch/AUR package
validate_arch_package() {
    local package="$1"

    # Check pacman first
    if pacman -Ss "^$package$" &>/dev/null; then
        local desc
        desc=$(pacman -Si "$package" 2>/dev/null | grep "^Description" | cut -d: -f2- | xargs || echo "No description")
        echo "{\"name\":\"$package\",\"type\":\"arch\",\"repo\":\"official\",\"description\":\"$desc\",\"valid\":true}"
        return 0
    fi

    # Check AUR (with caching)
    local cache_file="$CACHE_DIR/aur-$package"
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt $CACHE_TTL ]; then
        cat "$cache_file"
        return 0
    fi

    if paru -Si "$package" &>/dev/null 2>&1; then
        local desc
        desc=$(paru -Si "$package" 2>/dev/null | grep "^Description" | cut -d: -f2- | xargs || echo "No description")
        local result="{\"name\":\"$package\",\"type\":\"aur\",\"repo\":\"aur\",\"description\":\"$desc\",\"valid\":true}"
        echo "$result" | tee "$cache_file"
        return 0
    fi

    echo "{\"name\":\"$package\",\"type\":\"unknown\",\"repo\":\"none\",\"description\":\"Package not found\",\"valid\":false}"
    return 1
}

# Validate Flatpak package
validate_flatpak_package() {
    local package="$1"

    if flatpak search "$package" --columns=application 2>/dev/null | grep -q "^$package$"; then
        local desc
        desc=$(flatpak search "$package" --columns=description 2>/dev/null | head -1 || echo "No description")
        echo "{\"name\":\"$package\",\"type\":\"flatpak\",\"repo\":\"flathub\",\"description\":\"$desc\",\"valid\":true}"
        return 0
    fi

    echo "{\"name\":\"$package\",\"type\":\"flatpak\",\"repo\":\"none\",\"description\":\"Flatpak not found\",\"valid\":false}"
    return 1
}

# Batch validate packages
cmd_validate() {
    local type=""
    local packages=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type) type="$2"; shift 2 ;;
            --packages) packages="$2"; shift 2 ;;
            *) log_error "Unknown argument: $1"; return 1 ;;
        esac
    done

    if [ -z "$type" ] || [ -z "$packages" ]; then
        log_error "Missing required arguments: --type and --packages"
        return 1
    fi

    local results="[]"

    IFS=',' read -ra pkg_array <<< "$packages"
    for pkg in "${pkg_array[@]}"; do
        pkg=$(echo "$pkg" | xargs)  # Trim whitespace

        case "$type" in
            arch|aur)
                result=$(validate_arch_package "$pkg")
                ;;
            flatpak)
                result=$(validate_flatpak_package "$pkg")
                ;;
            *)
                log_error "Invalid package type: $type"
                return 1
                ;;
        esac

        results=$(echo "$results" | jaq --argjson pkg "$result" '. += [$pkg]')
    done

    echo "$results"
}

# Add package to packages.yaml
cmd_add() {
    local package=""
    local module=""
    local constraint=""
    local type="arch"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --package) package="$2"; shift 2 ;;
            --module) module="$2"; shift 2 ;;
            --constraint) constraint="$2"; shift 2 ;;
            --type) type="$2"; shift 2 ;;
            *) log_error "Unknown argument: $1"; return 1 ;;
        esac
    done

    if [ -z "$package" ] || [ -z "$module" ]; then
        log_error "Missing required arguments: --package and --module"
        return 1
    fi

    # Format package entry
    local package_entry="$package"
    if [ -n "$constraint" ]; then
        package_entry="${package}${constraint}"
    fi

    # Add flatpak prefix if needed
    if [ "$type" = "flatpak" ]; then
        package_entry="flatpak:${package_entry}"
    fi

    # Check if package already exists
    if yq eval ".packages.modules.${module}.packages | contains([\"$package_entry\"])" "$PACKAGES_YAML" 2>/dev/null | grep -q true; then
        log_warning "Package '$package_entry' already in module '$module'"
        return 0
    fi

    # Add to module, creating if needed
    yq eval -i "
        .packages.modules.${module} //= {\"enabled\": true, \"packages\": []} |
        .packages.modules.${module}.packages += [\"$package_entry\"] |
        .packages.modules.${module}.packages |= sort
    " "$PACKAGES_YAML"

    log_info "Added '$package_entry' to module '$module'"
}

# Create new module
cmd_create_module() {
    local name="${1:-}"
    local description="${2:-}"
    local enabled="${3:-true}"

    if [ -z "$name" ] || [ -z "$description" ]; then
        log_error "Missing required arguments: name and description"
        echo "Usage: package-add.sh create-module <name> <description> [enabled]"
        return 1
    fi

    # Check if module exists
    if yq eval ".packages.modules | has(\"$name\")" "$PACKAGES_YAML" 2>/dev/null | grep -q true; then
        log_error "Module '$name' already exists"
        return 1
    fi

    # Create module
    yq eval -i "
        .packages.modules.${name} = {
            \"enabled\": $enabled,
            \"description\": \"$description\",
            \"packages\": []
        }
    " "$PACKAGES_YAML"

    log_info "Created module '$name'"
}

# Show help
cmd_help() {
    cat <<EOF
Usage: package-add.sh <command> [options]

Commands:
  validate --type <arch|aur|flatpak> --packages <pkg1,pkg2>
    Validate packages exist in repositories
    Returns: JSON array of package metadata

  add --package <name> --module <module> [--constraint <constraint>] [--type <arch|flatpak>]
    Add package to packages.yaml
    Constraint examples: ==0.9.5, >=0.9.0, <1.0.0

  create-module <name> <description> [enabled]
    Create new module in packages.yaml

Examples:
  package-add.sh validate --type arch --packages "vim,neovim"
  package-add.sh add --package neovim --module development --constraint ">=0.9.0"
  package-add.sh create-module custom_tools "Custom development tools" true
EOF
}

# Main
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        validate)
            cmd_validate "$@"
            ;;
        add)
            cmd_add "$@"
            ;;
        create-module)
            cmd_create_module "$@"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            return 1
            ;;
    esac
}

main "$@"
