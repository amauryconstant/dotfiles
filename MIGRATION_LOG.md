# Arch Linux + Hyprland Migration Log

**Branch**: `arch-switch`
**Started**: October 2025
**Target**: Migrate from EndeavourOS + KDE Plasma to vanilla Arch Linux + Hyprland

## Migration Overview

This log documents the migration of dotfiles from an EndeavourOS-based KDE Plasma setup to a clean Arch Linux installation with Hyprland as the compositor.

**Historical Phases**: Phases 1-15 (EndeavourOS removal through boot system configuration) have been archived to [MIGRATION_LOG_ARCHIVE.md](./MIGRATION_LOG_ARCHIVE.md).

## Migration History

**Note**: Phases 1-15 archived. See [MIGRATION_LOG_ARCHIVE.md](./MIGRATION_LOG_ARCHIVE.md) for:
- **Phases 1-9**: Foundation (EndeavourOS removal, KDE archival, Hyprland implementation, security components, documentation, network management)
- **Phases 10-15**: Maturation (globals.yaml centralization, NVIDIA GPU drivers, file management, Waybar enhancements, power management, boot experience)

### Phase 16: Script Consolidation and Automation Improvements ✅
**Commit**: `6c13e61` - "Consolidate configuration scripts and update migration log"

**Changes Made**:
- **Script Consolidation** (9 scripts deleted, 3 comprehensive scripts created):
  - **New: `run_once_after_002_configure_system_services.sh.tmpl`** (352 lines):
    - Consolidated 4 separate service scripts into one comprehensive configuration
    - **Section 1 - Core Services**: Docker (with safe user group management), Bluetooth, conditional NVIDIA power management for laptops
    - **Section 2 - Ollama AI Service**: Optional AI model serving with NVIDIA GPU acceleration
    - **Section 3 - Tailscale VPN**: Secure mesh VPN with automatic authentication and subnet routing
    - **Section 4 - NetworkManager**: iwd backend configuration with secure credential storage (gnome-keyring)
    - Benefits: Single `systemctl daemon-reload`, consistent service verification, easier maintenance
    - Deleted scripts: `run_once_after_002_configure_services.sh.tmpl`, `run_once_after_006_configure_ollama.sh.tmpl`, `run_once_after_007_configure_tailscale.sh.tmpl`, `run_once_after_008_configure_networkmanager.sh.tmpl`

  - **New: `run_once_after_005_configure_git_tools.sh.tmpl`** (112 lines):
    - Consolidated git configuration into single comprehensive script
    - **Section 1 - Template Merge Driver**: Protects `{{ .variable }}` syntax during merge operations
    - **Section 2 - Git Hooks**: Installs hooks from `.gitscripts/` directory
    - Benefits: Single source of truth for git configuration, consistent setup
    - Deleted scripts: `run_once_after_005_configure_template_merge_driver.sh.tmpl`, `run_onchange_before_create_git_hooks.sh.tmpl`

  - **New: `run_once_after_008_configure_boot_system.sh.tmpl`** (667 lines):
    - Consolidated complete boot stack configuration into atomic operation
    - **Section 1 - GPU Driver Configuration**: NVIDIA DKMS with automatic detection, conflict resolution, initramfs setup
    - **Section 2 - Locale Configuration**: en_GB.UTF-8 system-wide (European date formats)
    - **Section 3 - Plymouth Boot Splash**: Graphical boot with theme configuration from globals.yaml
    - **Section 4 - SDDM Theme Installation**: Clone and validate solarized-sddm-theme from GitHub
    - **Section 5 - SDDM Display Manager**: Wayland native login with modular configuration
    - Benefits: Single `mkinitcpio -P` rebuild (instead of 3×), atomic boot configuration, consistent backup/rollback
    - Deleted scripts: `run_once_before_007_configure_gpu_drivers.sh.tmpl`, `run_once_before_008_configure_sddm.sh.tmpl`, `run_once_after_009_configure_plymouth.sh.tmpl`, `run_once_after_010_configure_sddm.sh.tmpl`

- **Printer Configuration** (`.chezmoidata/globals.yaml` - 8 new lines):
  - Added `printer` section with centralized network printer configuration
  - **Settings**: `name`, `ip`, `model`, `description` (Samsung M2070 Series)
  - Enables templated printer setup across scripts and documentation

- **Updated Scripts** (Minor templating improvements):
  - `run_once_after_001_generate_and_config_cli.sh.tmpl` (22 line updates): Enhanced logging and error handling
  - `run_once_after_003_setup_network_printer.sh.tmpl` (10 line updates): Now uses `{{ .globals.printer.* }}` template variables
  - `run_onchange_after_install_ai_models.sh.tmpl` (2 line updates): Improved model hash tracking
  - `run_onchange_after_install_extensions.sh.tmpl` (2 line updates): Enhanced extension hash tracking
  - `run_onchange_before_install_arch_packages.sh.tmpl` (4 line updates): Improved package state management

**Architecture Improvements**:
```
Consolidated Script Architecture:

Core Services (run_once_after_002):
├─→ Docker + Bluetooth + NVIDIA Power
├─→ Ollama AI (optional)
├─→ Tailscale VPN (optional)
└─→ NetworkManager + iwd backend

Git Tools (run_once_after_005):
├─→ Template merge driver protection
└─→ Git hooks installation

Complete Boot Stack (run_once_after_008):
├─→ GPU drivers (NVIDIA DKMS)
├─→ Locale configuration (en_GB.UTF-8)
├─→ Plymouth boot splash
├─→ SDDM theme installation
└─→ SDDM display manager configuration

Single Operations Instead of Multiple:
- systemctl daemon-reload: 1× (was 4×)
- mkinitcpio -P: 1× (was 3×)
- Service verification: Unified approach
- Backup/rollback: Consistent strategy
```

**Rationale**:
- **Maintainability**: Related configurations grouped together, easier to understand and modify
- **Performance**: Reduced redundant operations (daemon reloads, initramfs rebuilds)
- **Atomicity**: Boot stack changes apply atomically, reducing failure windows
- **Consistency**: Uniform error handling, logging, and verification across all sections
- **Template-Driven**: Printer configuration now centralized in globals.yaml (single source of truth)
- **Maturity**: Migration from granular scripts to comprehensive automation reflects system maturation

**Impact**:
- Total script reduction: 9 deleted → 3 consolidated (1,131 lines of comprehensive automation)
- Faster system configuration: Single daemon-reload and initramfs rebuild
- Easier maintenance: Related services configured in logical groups
- Improved reliability: Atomic boot configuration changes with consistent backup strategy
- Better organization: Clear sections with visual separators and comprehensive documentation
- Printer setup now templated: Change printer details once in globals.yaml
- Cleaner script directory: Fewer files, clearer purpose
- No functional changes: All previous functionality preserved, just better organized
- Net line change: ±0 (reorganization, not addition)

---

### Phase 17: Dynamic Wallpaper System with Automatic Color Theming ✅
**Commit**: `(pending)` - "Implement dynamic wallpaper rotation with wallust color palette integration"

**Changes Made**:
- **Wallpaper Daemon Replacement** (`.chezmoidata/packages.yaml`):
  - Replaced `hyprpaper` (static) with `swww` (dynamic transitions, AUR)
  - Added `wallust` (color palette generator from wallpapers, AUR)

- **Automatic Wallpaper Rotation**:
  - **New: `run_once_after_007_setup_wallpaper_timer.sh.tmpl`**: Configures systemd timer for 30-minute rotation
  - **New: `wallpaper-cycle.timer`** + **`wallpaper-cycle.service`**: Systemd units for automated rotation
  - **New: `random-wallpaper.sh.tmpl`**: Selects random wallpaper from `~/Pictures/wallpapers/`
  - **New: `set-wallpaper.sh.tmpl`**: Sets wallpaper via swww and triggers wallust color generation

- **CLI Functions** (Zsh):
  - `random-wallpaper`: User command for manual random wallpaper selection
  - `set-wallpaper`: User command to set specific wallpaper image

- **Wallust Color Palette System**:
  - **New: `wallust.toml.tmpl`** (116 lines): K-means clustering in Lab color space, dark16 palette
  - **8 Color Templates**: Generate application-specific color files for Hyprland, Hyprlock, Waybar, Wofi, Dunst, Wlogout, Ghostty, Shell
  - Output location: `~/.config/{app}/wallust/` subdirectories (NOT managed by chezmoi)
  - Triggered automatically when wallpaper changes via `set-wallpaper.sh`

**Architecture**:
```
Automatic Rotation (systemd timer every 30min):
└─→ random-wallpaper → set-wallpaper.sh
    ├─→ swww: Smooth wallpaper transition
    └─→ wallust: Extract palette → Generate 8 app color files

Color Integration (applications source generated files):
├─→ Hyprland, Hyprlock, Waybar, Wofi
├─→ Dunst, Wlogout, Ghostty, Shell
└─→ All automatically match wallpaper palette
```

**Rationale**:
- **Unified theming**: Desktop environment automatically adapts to wallpaper colors
- **Perceptual accuracy**: Lab color space ensures visually pleasing palettes
- **Automation**: Systemd timer provides reliable rotation without manual intervention
- **Flexibility**: Manual controls available via CLI functions
- **Separation of concerns**: Generated color files excluded from chezmoi (ephemeral state)

**Impact**:
- Visual consistency across 8 applications without manual color coordination
- Automatic wallpaper rotation every 30 minutes with smooth transitions
- Algorithm-driven aesthetics using K-means clustering
- User controls: `random-wallpaper`, `set-wallpaper <path>`, systemd timer management
- Total new files: 17 (1 setup script, 2 utilities, 2 functions, 2 systemd units, 1 config, 8 color templates)

---

## Next Steps

---

**Last Updated**: 2025-10-20
