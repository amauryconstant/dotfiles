#!/usr/bin/env bash

# SSH Key Regeneration Tool
# Purpose: Regenerate SSH key and reimport into chezmoi dotfiles
# Requirements: Arch Linux, chezmoi, age encryption, gum (UI library)

# Source the UI library
if [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
else
    echo "Error: UI library not found at $UI_LIB" >&2
    exit 1
fi

# =============================================================================
# INTERNAL FUNCTIONS
# =============================================================================

_show_usage() {
    local chezmoi_source chezmoi_ssh_dir
    chezmoi_source="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"
    chezmoi_ssh_dir="$chezmoi_source/private_dot_ssh"

    ui_error "Usage: regen-ssh-key <keyname>"
    echo ""
    echo "Examples:"
    echo "  regen-ssh-key github"
    echo "  regen-ssh-key gitlab"
    echo "  regen-ssh-key ovh-server"
    echo ""
    echo "Available keys:"
    if [ -d "$chezmoi_ssh_dir" ]; then
        find "$chezmoi_ssh_dir" -name 'encrypted_private_*.age' -type f 2>/dev/null | while read -r file; do
            basename "$file" | sed 's/^encrypted_private_/  - /' | sed 's/\.age$//'
        done
    fi
}

_validate_prerequisites() {
    ui_step "Validating prerequisites"

    # Check chezmoi
    if ! command -v chezmoi >/dev/null 2>&1; then
        ui_error "chezmoi not found. Install it first."
        exit 1
    fi

    # Check ssh-keygen
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        ui_error "ssh-keygen not found. Install openssh."
        exit 1
    fi

    # Check encryption key exists
    if [ ! -f "$HOME/.keys/dotfiles-key.txt" ]; then
        ui_error "Encryption key not found at ~/.keys/dotfiles-key.txt"
        echo "Run 'chezmoi init' or retrieve key from Vaultwarden"
        exit 1
    fi

    ui_success "Prerequisites validated"
}

_backup_existing_keys() {
    local keyname="$1"
    local ssh_dir="$2"
    local backup_dir="$3"
    local private_key="$ssh_dir/$keyname"
    local public_key="$ssh_dir/${keyname}.pub"

    ui_step "Backing up existing keys"

    # Check if keys exist
    if [ ! -f "$private_key" ] && [ ! -f "$public_key" ]; then
        ui_info "No existing keys found for '$keyname', skipping backup"
        return 0
    fi

    # Create backup directory
    mkdir -p "$backup_dir"

    # Backup private key if exists
    if [ -f "$private_key" ]; then
        cp -p "$private_key" "$backup_dir/"
        ui_info "Backed up: $private_key"
    fi

    # Backup public key if exists
    if [ -f "$public_key" ]; then
        cp -p "$public_key" "$backup_dir/"
        ui_info "Backed up: $public_key"
    fi

    ui_success "Keys backed up to: $backup_dir"
}

_generate_new_key() {
    local keyname="$1"
    local ssh_dir="$2"
    local private_key="$ssh_dir/$keyname"
    local public_key="$ssh_dir/${keyname}.pub"

    ui_step "Generating new ED25519 keypair"

    # Remove old keys if they exist (already backed up)
    rm -f "$private_key" "$public_key"

    # Prompt for comment
    local comment
    comment=$(ui_input "Enter key comment (e.g., email)" "")

    # Generate key
    if [ -n "$comment" ]; then
        ssh-keygen -t ed25519 -C "$comment" -f "$private_key" -N "" >/dev/null 2>&1
    else
        ssh-keygen -t ed25519 -f "$private_key" -N "" >/dev/null 2>&1
    fi

    # Validate key generation
    if [ ! -f "$private_key" ] || [ ! -f "$public_key" ]; then
        ui_error "Key generation failed"
        exit 1
    fi

    ui_success "Generated: $private_key"
    ui_success "Generated: $public_key"
}

_import_into_chezmoi() {
    local keyname="$1"
    local ssh_dir="$2"
    local chezmoi_ssh_dir="$3"
    local private_key="$ssh_dir/$keyname"
    local public_key="$ssh_dir/${keyname}.pub"

    ui_step "Importing keys into chezmoi"

    # Add private key with encryption
    ui_info "Encrypting private key..."
    chezmoi add --encrypt "$private_key"

    # Add public key with encryption
    ui_info "Encrypting public key..."
    chezmoi add --encrypt "$public_key"

    # Validate import
    local encrypted_private="$chezmoi_ssh_dir/encrypted_private_${keyname}.age"
    local encrypted_public="$chezmoi_ssh_dir/encrypted_${keyname}.pub.age"

    if [ ! -f "$encrypted_private" ]; then
        ui_error "Private key encryption failed: $encrypted_private not found"
        exit 1
    fi

    if [ ! -f "$encrypted_public" ]; then
        ui_error "Public key encryption failed: $encrypted_public not found"
        exit 1
    fi

    ui_success "Imported: $encrypted_private"
    ui_success "Imported: $encrypted_public"
}

_display_public_key() {
    local keyname="$1"
    local ssh_dir="$2"
    local public_key="$ssh_dir/${keyname}.pub"

    ui_separator
    ui_title "PUBLIC KEY"
    ui_separator

    cat "$public_key"

    ui_separator
    ui_info "Copy this public key and add it to:"

    case "$keyname" in
        github)
            echo "  → GitHub: https://github.com/settings/keys"
            ;;
        gitlab)
            echo "  → GitLab: https://gitlab.com/-/profile/keys"
            ;;
        ovh-server)
            echo "  → OVH Server: ~/.ssh/authorized_keys"
            ;;
        *)
            echo "  → Your target service/server"
            ;;
    esac

    ui_separator
}

_display_next_steps() {
    local keyname="$1"
    local ssh_dir="$2"
    local chezmoi_source="$3"

    ui_title "NEXT STEPS"

    echo "1. Add public key to service (displayed above)"
    echo "2. Test connection:"

    case "$keyname" in
        github)
            echo "   ssh -T git@github.com"
            ;;
        gitlab)
            echo "   ssh -T git@gitlab.com"
            ;;
        ovh-server)
            echo "   ssh ovh"
            ;;
        *)
            echo "   ssh <your-service>"
            ;;
    esac

    echo "3. Commit changes:"
    echo "   cd $chezmoi_source"
    echo "   git add private_dot_ssh/"
    echo "   git commit -m 'Regenerate SSH key: $keyname'"
    echo "   git push"

    ui_separator
}

# =============================================================================
# PUBLIC FUNCTION
# =============================================================================

regen-ssh-key() {
    # Check arguments
    if [ $# -ne 1 ]; then
        _show_usage
        return 1
    fi

    local keyname="$1"
    local ssh_dir="$HOME/.ssh"
    local chezmoi_source chezmoi_ssh_dir backup_dir

    chezmoi_source="$(chezmoi source-path)"
    chezmoi_ssh_dir="$chezmoi_source/private_dot_ssh"
    backup_dir="$ssh_dir/backup-${keyname}-$(date +%Y-%m-%d-%H%M%S)"

    # Header
    ui_title "SSH KEY REGENERATION: $keyname"

    # Confirm action
    if ! ui_confirm "Regenerate SSH key '$keyname'? Old keys will be backed up."; then
        ui_info "Operation cancelled"
        return 0
    fi

    # Execute steps
    _validate_prerequisites
    _backup_existing_keys "$keyname" "$ssh_dir" "$backup_dir"
    _generate_new_key "$keyname" "$ssh_dir"
    _import_into_chezmoi "$keyname" "$ssh_dir" "$chezmoi_ssh_dir"

    # Success
    ui_success "SSH key '$keyname' regenerated successfully"

    # Display results
    _display_public_key "$keyname" "$ssh_dir"
    _display_next_steps "$keyname" "$ssh_dir" "$chezmoi_source"
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    regen-ssh-key "$@"
fi
