# Technical Context: Chezmoi Dotfiles Management System

## Technologies Used

### Core Technologies

1. **Chezmoi**
   - Version: Latest stable
   - Purpose: Core dotfiles management engine
   - Features: Templates, encryption, cross-platform support
   - Documentation: [chezmoi.io](https://www.chezmoi.io/)

2. **Age Encryption**
   - Implementation: `rage` (Rust implementation of age)
   - Purpose: Secure encryption of sensitive files
   - Features: Modern encryption, simple key management
   - Documentation: [age-encryption.org](https://age-encryption.org/)

3. **Go Templates**
   - Purpose: Template processing for configuration files
   - Features: Conditionals, loops, functions, includes
   - Documentation: [Go text/template](https://pkg.go.dev/text/template)

4. **Shell Scripting**
   - Shell: POSIX sh (for maximum compatibility)
   - Purpose: System configuration and package management
   - Features: Cross-distribution compatibility

### Package Management

1. **Arch Linux**
   - Primary: `pacman` (official repositories)
   - Secondary: `yay` (AUR helper)
   - Strategies: Official repos, AUR binaries, AUR source

2. **Debian/Ubuntu**
   - Primary: `apt` (official repositories)
   - Secondary: PPAs, snap, flatpak
   - Strategies: Official repos, PPAs, snaps

3. **Fedora**
   - Primary: `dnf` (official repositories)
   - Secondary: COPR, snap, flatpak
   - Strategies: Official repos, COPR, snaps

#### Package Transitions

Automatic handling of package restructuring that causes file conflicts:

- **linux-firmware split (June 2025)**: Monolithic package split into vendor-specific packages
- **Detection**: Version-based detection in update scripts
- **Resolution**: `--overwrite` flags for conflicting firmware directories
- **Implementation**: `handle_package_transitions()` in `run_onchange_before_update_arch_packages.sh.tmpl`

### Development Tools

1. **VSCode**
   - Extensions: Managed through `.chezmoidata/extensions.yaml`
   - Settings: Templated configuration
   - Integration: Git, language servers, AI tools

2. **AI Tools**
   - Ollama: Local LLM hosting
   - Models: Defined in `.chezmoidata/ai.yaml`
   - Integration: VSCode extensions (Continue, Claude Dev)

3. **Shell Environment**
   - Primary: ZSH with antidote
   - Prompt: Starship
   - Terminal: Ghostty
   - Utilities: Modern replacements (eza, bat, ripgrep, etc.)

4. **Git**
   - Diff Tool: Delta
   - Merge Tool: Mergiraf
   - Hooks: Managed through `.gitscripts`

## Development Setup

### Directory Structure

```
.
├── .chezmoi.yaml.tmpl           # Core configuration template
├── .chezmoidata/                # Data files
│   ├── ai.yaml                  # AI model configuration
│   ├── colors.yaml              # Color scheme definitions
│   ├── extensions.yaml          # VSCode extensions
│   ├── globals.yaml             # Global environment variables
│   └── packages.yaml            # Package management configuration
├── .chezmoiignore               # Files to ignore
├── .chezmoiscripts/             # Lifecycle scripts
│   ├── run_before_*             # Scripts to run before applying
│   ├── run_after_*              # Scripts to run after applying
│   └── run_onchange_*           # Scripts to run when content changes
├── .clinerules/                 # Cline AI rules
├── .data/                       # Additional data files
├── .gitscripts/                 # Git hook scripts
├── private_dot_config/          # Private configuration files
├── private_dot_keys/            # Encrypted keys and secrets
├── private_dot_ssh/             # SSH configuration and keys
└── README.md                    # Project documentation
```

### Script Naming Conventions

Scripts follow a strict naming convention to control execution order:

```
run_[frequency]_[timing]_[order]_[description].sh.tmpl
```

- `frequency`: `once` or `onchange`
- `timing`: `before` or `after`
- `order`: 3-digit number (001, 002, etc.)
- `description`: Clear description of purpose

Example: `run_once_before_001_install_package_manager.sh.tmpl`

### File Naming Conventions

Files follow chezmoi's naming conventions with extensions:

- `dot_`: Files that should be prefixed with a dot
- `private_`: Files that should not be world-readable
- `executable_`: Files that should be executable
- `symlink_`: Symlinks to other files
- `encrypted_`: Files encrypted with age
- `.tmpl`: Files processed as templates

Example: `private_dot_config/git/config.tmpl`

## Technical Constraints

### Cross-Distribution Compatibility

1. **Package Availability**
   - Not all packages are available on all distributions
   - Package names may differ between distributions
   - Installation methods vary by distribution

2. **System Paths**
   - Configuration file locations may vary
   - System binaries may be in different locations
   - Service management differs between distributions

3. **Version Differences**
   - Different distributions ship different software versions
   - Features may not be available in all versions
   - Configuration syntax may change between versions

### Security Requirements

1. **Encryption**
   - Sensitive files must be encrypted
   - Encryption keys must be properly managed
   - Decryption must be manual (no automated decryption)

2. **Permissions**
   - SSH keys and config files must have correct permissions
   - Private configuration files must not be world-readable
   - Scripts must run with appropriate privileges

### Performance Considerations

1. **Script Execution**
   - Scripts should be optimized for speed
   - Avoid unnecessary operations
   - Use quick checks to skip unnecessary work

2. **Package Installation**
   - Package installation is time-consuming
   - Use strategies to minimize build time
   - Prefer binary packages when appropriate

## Dependencies

### External Tools

1. **Required Tools**
   - `git`: Version control
   - `chezmoi`: Dotfiles management
   - `rage`: Age encryption implementation
   - Distribution package manager (`pacman`, `apt`, `dnf`)

2. **Optional Tools**
   - `yay`: AUR helper (Arch Linux)
   - `snap`: Universal package manager
   - `flatpak`: Universal package manager
   - `docker`: Container management

### System Services

1. **Core Services**
   - `systemd`: Service management
   - `NetworkManager`: Network configuration
   - `dbus`: Inter-process communication

2. **Optional Services**
   - `ollama`: Local LLM service
   - `docker`: Container service
   - `sshd`: SSH server

### External Dependencies

1. **Package Repositories**
   - Official distribution repositories
   - Third-party repositories (AUR, PPAs, COPR)
   - Container registries

2. **Online Services**
   - GitHub: Repository hosting
   - Ollama models: AI model repository
   - VSCode marketplace: Extension repository

## Tool Usage Patterns

### Chezmoi Commands

```bash
# Initialize chezmoi
chezmoi init

# Apply changes
chezmoi diff        # Preview changes
chezmoi apply       # Apply changes

# Update from source
chezmoi update      # Pull and apply changes

# Edit files
chezmoi edit <file> # Edit source file
chezmoi add <file>  # Add file to chezmoi

# Merge conflicts
chezmoi merge <file> # Merge specific file
chezmoi merge-all    # Merge all files with conflicts
```

### Package Management

```bash
# Arch Linux
pacman -S <package>  # Install from official repos
yay -S <package>     # Install from AUR

# Debian/Ubuntu
apt-get install <package>  # Install from official repos
add-apt-repository ppa:<ppa> && apt-get update  # Add PPA

# Fedora
dnf install <package>  # Install from official repos
dnf copr enable <copr> # Add COPR repository
```

### Encryption Workflow

```bash
# Add encrypted file
chezmoi add --encrypt <file>

# Edit encrypted file
chezmoi edit <encrypted_file>

# Decrypt file (manual only)
chezmoi decrypt <encrypted_file>
```

## Development Workflow

### Adding New Features

1. **Plan Changes**
   - Identify affected components
   - Determine cross-distribution impact
   - Design distribution-specific adaptations

2. **Implement Changes**
   - Update data files if needed
   - Create or modify templates
   - Create or modify scripts
   - Test on primary distribution

3. **Test Cross-Distribution**
   - Test on secondary distributions
   - Verify behavior is consistent
   - Adjust for distribution-specific differences

4. **Document Changes**
   - Update README if needed
   - Document distribution-specific behavior
   - Document any limitations or constraints

### Maintenance Workflow

1. **Regular Updates**
   - Pull latest changes: `chezmoi update`
   - Check for conflicts: `chezmoi status`
   - Resolve conflicts if needed: `chezmoi merge-all`
   - Apply changes: `chezmoi apply`

2. **Adding New Machines**
   - Clone repository
   - Initialize chezmoi: `chezmoi init`
   - Apply configuration: `chezmoi apply`
   - Verify installation: `chezmoi verify`

3. **Troubleshooting**
   - Check logs: `chezmoi doctor`
   - Verify state: `chezmoi verify`
   - Compare with source: `chezmoi diff`
   - Apply specific files: `chezmoi apply <file>`
