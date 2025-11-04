# Arch Linux + Hyprland Migration Log - Archive

**Archive Date**: October 2025
**Branch**: `arch-switch` (historical)
**Status**: Completed phases from initial migration

This archive contains Phases 1-15 of the migration from EndeavourOS + KDE Plasma to vanilla Arch Linux + Hyprland. These phases established the complete foundation and maturation of the desktop environment, from initial setup through system configuration optimization.

**For current migration status, see**: [MIGRATION_LOG.md](./MIGRATION_LOG.md)

---

## Archived Phases (1-15)

### Overview

- **Phases 1-9**: Foundation phase establishing the core Hyprland desktop environment, security components, documentation, and network management
- **Phases 10-15**: Maturation phase implementing centralized configuration, hardware support, interactive interfaces, and professional boot experience

### Phase 1: Remove Distribution Dependencies ✅
**Commit**: `7d3449c` - "Remove dependency to endeavouros"

**Changes Made**:
- Removed `.chezmoiscripts/run_once_before_004_install_distributions_and_os_specifics.sh.tmpl`
  - This script contained EndeavourOS-specific configurations:
    - Mirror optimization with `rate-mirrors`
    - EndeavourOS system update via `eos-update`
    - NVIDIA driver installation using `nvidia-inst` tool
    - NVIDIA kernel update checks
  - No longer needed for vanilla Arch installation (NVIDIA drivers now managed via archinstall baseline)
- Renumbered subsequent `run_once_before_*` scripts to maintain sequential order:
  - `005_instantiate_encryption_key.sh.tmpl` → `004_instantiate_encryption_key.sh.tmpl`
  - `006_install_chezmoi_modify_manager.sh.tmpl` → `005_install_chezmoi_modify_manager.sh.tmpl`
  - `007_create_maintenance_user.sh.tmpl` → `006_create_maintenance_user.sh.tmpl`

**Impact**:
- System no longer requires EndeavourOS-specific tools or configurations
- NVIDIA drivers are now installed via archinstall baseline (documented in Phase 3)
- Clean sequential script numbering maintained (001-006)

### Phase 2: Archive KDE Configuration ✅
**Commit**: `b336883` - "Archive KDE configuration files"

**Changes Made**:
- Created `archives/` directory structure with documentation
- Moved KDE Plasma configuration files to `archives/kde/private_dot_config/`:
  - `modify_private_kdeglobals.tmpl` - KDE global settings modifier
  - `private_kdeglobals.src.ini` - KDE global settings source
  - `modify_private_kwinrc` - KWin window manager modifier
  - `private_kwinrc.src.ini` - KWin window manager source
  - `color-schemes/BreezeSolarizedDark.colors` - Custom color scheme
  - `color-schemes/BreezeSolarizedLight.colors` - Custom color scheme
- Updated `.chezmoiignore` to exclude `archives/` directory from deployment
- Added archive log entry to `archives/README.md`

**Rationale**:
- KDE configs preserved for reference during Hyprland configuration
- Files still version-controlled but not deployed to system
- Maintains historical record of color scheme preferences (oksolar variants)
- Clean separation between active and archived configurations

**Impact**: Repository no longer deploys KDE-specific configuration while preserving it for reference.

### Phase 3: Document archinstall Baseline Packages ✅
**Commit**: `cb738db` - "Document archinstall baseline packages and reorganize NVIDIA drivers"

**Changes Made**:
- Added `archinstall_baseline` section to `.chezmoidata/packages.yaml`
- Documented 31 packages installed during archinstall setup with Hyprland profile:
  - **Core System** (5 packages): `base`, `base-devel`, `linux-firmware`, `linux`, `intel-ucode`
  - **Hyprland Desktop** (12 packages): `hyprland`, `dunst`, `kitty`, `uwsm`, `dolphin`, `wofi`, `xdg-desktop-portal-hyprland`, `qt5-wayland`, `qt6-wayland`, `polkit-kde-agent`, `grim`, `slurp`
  - **Audio - PipeWire** (7 packages): `pipewire`, `pipewire-alsa`, `pipewire-jack`, `pipewire-pulse`, `gst-plugin-pipewire`, `libpulse`, `wireplumber`
  - **Network** (1 package): `networkmanager`
  - **Bootloader & Encryption** (1 package): `cryptsetup` (systemd-boot included in systemd)
  - **Graphics Drivers** (5 packages): `nvidia-open`, `nvidia-utils`, `nvidia-settings`, `lib32-nvidia-utils`, `nvidia-hook`
- Moved NVIDIA drivers from `packages.install.arch.packages.graphics_drivers` to `archinstall_baseline.graphics_drivers`
- Updated Phase 1 note: NVIDIA drivers originally added are now managed by archinstall baseline

**System Configuration Documented**:
- Bootloader: systemd-boot
- Encryption: LUKS (via cryptsetup)
- Graphics: NVIDIA open-source drivers

**Rationale**:
- Establishes clear baseline of system-installed packages for redundancy checking
- Documents initial system state from archinstall Hyprland profile installation
- Prevents duplicate package management between archinstall and chezmoi
- NVIDIA drivers remain system-managed (updated via `pacman -Syu`) as appropriate for critical hardware drivers
- Preserves knowledge of what the base system provides vs. what chezmoi manages

**Impact**:
- Documentation-only change (no package management behavior affected)
- `archinstall_baseline` section is NOT processed by installation scripts
- Removed 5 packages from chezmoi management (NVIDIA drivers) to avoid conflicts
- Future package additions can be checked against this baseline to avoid redundancy

### Phase 4: Implement Hyprland Desktop Environment ✅
**Commit**: `0542d23` - "Add comprehensive Hyprland configuration with waybar"

**Changes Made**:
- Added `waybar` package to `packages.yaml` wayland_desktop section for status bar functionality
- Created comprehensive Hyprland configuration with modular structure (2,418 lines added across 15 files):
  - **Core Configuration** (`~/.config/hypr/`):
    - `hyprland.conf` - Main entry point sourcing modular configs
  - **Modular Configuration Files** (`~/.config/hypr/conf/`):
    - `monitor.conf` - Display setup with scaling and positioning
    - `autostart.conf` - Essential background services (waybar, dunst, polkit)
    - `environment.conf` - Wayland environment variables and NVIDIA GPU acceleration
    - `input.conf` - Keyboard, mouse, and touchpad configuration
    - `general.conf` - Layout, gaps, borders, and color scheme
    - `decoration.conf` - Window styling with shadows and blur effects (123 lines)
    - `animations.conf` - Smooth bezier curves and window transitions (129 lines)
    - `bindings.conf.tmpl` - Comprehensive keybindings for window/workspace management (274 lines, templated)
    - `windowrules.conf` - Application-specific window and workspace behavior (147 lines)
  - **Application Launchers**:
    - `wofi/config` - Application launcher configuration (221 lines)
    - `wofi/style.css.tmpl` - Launcher styling with oksolar color scheme (335 lines, templated)
  - **Status Bar** (`~/.config/waybar/`):
    - `config.tmpl` - Waybar modules and layout (379 lines, templated)
    - `style.css.tmpl` - Waybar styling with oksolar colors (424 lines, templated)

**Configuration Highlights**:
- **Modular Architecture**: Each aspect (input, display, animations, etc.) in separate files for maintainability
- **Template Integration**: Bindings, waybar, and wofi use Go templates for user-specific customization
- **oksolar Color Scheme**: Consistent application of custom color scheme across all components
- **NVIDIA Support**: Explicit environment variables for GPU acceleration and Wayland compatibility
- **Comprehensive Keybindings**:
  - Window management (Super+[hjkl], Super+Arrow keys)
  - Workspace navigation (Super+[0-9])
  - Application launchers (Super+D for wofi, Super+Q for terminal)
  - Screenshot utilities (Super+S with grim/slurp)
- **Status Bar Features**: Network, audio, CPU, memory, temperature, battery, clock modules

**Rationale**:
- Replaces KDE Plasma with lightweight Hyprland compositor
- Provides complete desktop environment setup through dotfiles
- Modular structure allows easy customization and maintenance
- Template-driven configuration ensures user-specific values (color preferences, keybindings)
- All configuration version-controlled and reproducible via chezmoi

**Impact**:
- System now has complete Hyprland desktop environment configuration
- Waybar provides status bar functionality (15 configuration modules)
- Wofi provides application launcher with custom styling
- Total of 2,418 lines of configuration across 15 files
- Ready for deployment on fresh Arch + Hyprland installation

### Phase 5: Migrate to ghostty and neovim ✅
**Commit**: `08a3a41` - "Migrate terminal and editor to ghostty and neovim"

**Changes Made**:
- **Package Management** (`.chezmoidata/packages.yaml`):
  - Added `neovim` to `terminal_essentials.list` (line 81)
  - Extended `delete.arch` section to remove redundant baseline packages:
    - `htop` - Redundant with btop/glances in terminal_utils
    - `vim` - Replaced by neovim
    - **Note**: Kept `kitty` from archinstall baseline as backup terminal
- **Hyprland Keybindings** (`private_dot_config/hypr/conf/bindings.conf.tmpl:32`):
  - Changed terminal launcher from `kitty` to `ghostty`
  - Super+Return now launches ghostty as primary terminal
- **Wofi Integration** (`private_dot_config/wofi/config:115`):
  - Updated `term=ghostty` for terminal applications launched from wofi
  - Updated comment reference from `vim, htop` to `nvim, btop`
- **Waybar Documentation** (`private_dot_config/waybar/config.tmpl`):
  - Line 203: Updated commented example `"on-click": "kitty htop"` → `"on-click": "ghostty btop"`
  - Line 220: Updated commented example `"on-click": "kitty htop"` → `"on-click": "ghostty btop"`
- **Environment Variables** (`private_dot_config/shell/login:6-7`):
  - Changed `EDITOR=nano` → `EDITOR=nvim`
  - Changed `VISUAL=code` → `VISUAL=nvim`

**Terminal Architecture**:
- **Primary**: ghostty (managed by chezmoi, launched via Super+Return)
- **Backup**: kitty (from archinstall baseline, available via wofi launcher)
- **Rationale**: Dual-terminal approach provides safety net during initial Hyprland setup

**Rationale**:
- **ghostty**: Modern GPU-accelerated terminal with better Wayland support
- **neovim**: Modern vim replacement with LSP support and active development
- **htop removal**: Redundant with btop (better UI), nvitop (GPU monitoring), and glances (comprehensive monitoring)
- **vim removal**: Replaced by neovim while maintaining vim-compatible workflow
- **kitty preservation**: Minimal overhead (~5-10MB) provides emergency fallback terminal

**Impact**:
- System-wide editor preference set to neovim for git, system tools, and CLI applications
- Primary terminal switched to ghostty across all Hyprland integrations
- Consistent tool references across waybar, wofi, and keybindings
- Cleanup of redundant monitoring tools (htop) and editors (vim)
- Backup terminal (kitty) available via `Super+D` → type "kitty" if ghostty issues occur

### Phase 6: Add Critical Security and Usability Components ✅
**Commit**: `b12f924` - "Add critical security and usability components for Hyprland deployment"

**Summary**: Added essential security (hyprlock, hypridle) and usability (cliphist, wlogout, pamixer, brightnessctl) packages. Created 4 configuration files (244 lines) for screen locking, idle management, power menu, and clipboard history. Enabled essential daemons in Hyprland autostart and added 4 new keybindings for lock screen, power menu, clipboard, and brightness control.

**Impact**: Desktop environment became production-ready with complete security and usability features. Screen automatically locks after inactivity, GUI power menu for session management, clipboard history accessible via keyboard shortcut, and media keys functional.

### Phase 7: Add Comprehensive Hyprland Documentation ✅
**Commit**: `a9887ff` - "Add comprehensive Hyprland desktop environment documentation"

**Summary**: Added 103 lines of documentation across CLAUDE.md (75 lines of technical guidance) and README.md (36 lines of user documentation). Documented complete desktop stack (Hyprland + Waybar + Wofi), terminal architecture (Ghostty + Kitty), modular configuration structure, package management with archinstall baseline tracking, and testing procedures.

**Impact**: Established comprehensive technical reference for Hyprland configuration patterns, testing procedures, and component interactions. Created single source of truth for desktop environment specifications.

### Phase 8: Enhance Hyprland Desktop with Notifications and Keybinds ✅
**Commit**: `ebed785` - "Enhance Hyprland desktop with dunst notifications, wallpaper management, and keybinds system"

**Summary**: Corrected all commit hashes in migration history to match actual git repository (Phases 1-6 hashes updated). Added missing Phase 7 documentation entry. Renumbered phases to maintain chronological accuracy. This phase focused on commit hash verification and migration log accuracy.

**Impact**: Migration log now accurately references all actual commits in repository with correct chronological order. Enables reliable git operations (checkout, bisect, revert) based on documented commits.

### Phase 9: Configure NetworkManager with iwd Backend ✅
**Commit**: `160c266` - "Configure NetworkManager with iwd backend for WiFi management"

**Summary**: Added NetworkManager and gnome-keyring packages. Created 61-line configuration script for NetworkManager + iwd backend setup. Updated archinstall baseline documentation to clarify iwd usage. Added gnome-keyring daemon to Hyprland autostart (4 lines) and network module click handler to Waybar (1 line).

**Impact**: Complete network management stack configured. WiFi credentials stored securely via gnome-keyring. NetworkManager accessible via waybar network icon click (spawns nmtui in ghostty). iwd backend provides modern WiFi management replacing wpa_supplicant.

---

**Archive Note**: These nine phases established the complete foundation for the Arch Linux + Hyprland migration, including desktop environment, security components, documentation, and network management. Subsequent phases (10+) focus on environment configuration centralization, hardware support (GPU drivers, file management), and interface refinements. See [MIGRATION_LOG.md](./MIGRATION_LOG.md) for current migration status.

### Phase 10: Centralize Environment Configuration with globals.yaml ✅
**Commit**: `51975cd` - "Centralize environment configuration with globals.yaml"

**Changes Made**:
- **New Data File** (`.chezmoidata/globals.yaml` - 34 lines):
  - Created central source of truth for environment variables and default applications
  - **Applications section**: Default editor (`nvim`), visual editor (`code`), browser (`firefox`)
  - **XDG section**: Base directory specification paths (config, cache, data, state)
  - **Paths section**: User binaries, package managers (cargo, go), project directories
  - All values documented with comments explaining usage context

- **Template Migration** (`private_dot_config/shell/login` → `login.tmpl`):
  - Converted static shell script to Go template (40 lines)
  - Replaced hardcoded values with `{{ .globals.* }}` template variables
  - **XDG variables**: Now reference `{{ .globals.xdg.* }}` with fallback syntax
  - **PATH setup**: Uses `{{ .globals.paths.local_bin }}` and `{{ .globals.paths.local_sbin }}`
  - **Software Envs**: `$EDITOR`, `$VISUAL`, `$BROWSER` from `{{ .globals.applications.* }}`
  - **Package Managers**: `$CARGO_HOME`, `$GOPATH` from `{{ .globals.paths.* }}`
  - **Project Paths**: `$PROJECTS`, `$WORKTREES` from `{{ .globals.paths.* }}`

- **New XDG MIME Configuration** (`private_dot_config/mimeapps.list.tmpl` - 25 lines):
  - Created templated MIME type associations synchronized with shell environment
  - **Browser associations**: HTTP/HTTPS schemes use `{{ .globals.applications.browser }}.desktop`
  - **Text editor associations**: Plain text, markdown, logs use `{{ .globals.applications.editor }}.desktop`
  - **Visual editor associations**: Scripts, JSON, YAML, TOML use `{{ .globals.applications.visual }}.desktop`
  - Single source of truth: MIME types automatically match `$EDITOR`, `$VISUAL`, `$BROWSER` variables

- **Shell Integration Updates**:
  - `private_dot_config/shell/env` (line 6): Fixed path reference `$HOME/.config/sh/interactive` → `$HOME/.config/shell/interactive`
  - `private_dot_config/zsh/dot_zshenv`: Removed duplicate PATH setup and `login` sourcing
    - Deleted redundant `path=(...)` array configuration (zsh-specific, now in login template)
    - Removed manual sourcing of `login` file (handled by zsh initialization chain)
    - Kept only essential: sourcing `env` and `typeset -gU path fpath` for deduplication

**Architecture Improvements**:
```
.chezmoidata/globals.yaml (Single Source of Truth)
    ├─→ shell/login.tmpl (Shell Environment Variables)
    │   ├─→ $EDITOR, $VISUAL, $BROWSER
    │   ├─→ $XDG_CONFIG_HOME, $XDG_CACHE_HOME, etc.
    │   └─→ $PATH, $CARGO_HOME, $GOPATH, etc.
    └─→ mimeapps.list.tmpl (XDG MIME Associations)
        ├─→ text/* → nvim.desktop
        ├─→ x-scheme-handler/http* → firefox.desktop
        └─→ application/* → code.desktop
```

**Rationale**:
- **DRY Principle**: Eliminates hardcoded duplication across shell config and MIME types
- **Single Source of Truth**: Change default browser once in `globals.yaml`, applies everywhere
- **Consistency**: Shell environment variables automatically match XDG MIME type associations
- **Maintainability**: Centralized configuration easier to audit and update
- **Template Best Practice**: Demonstrates proper use of `.chezmoidata/` for shared configuration values
- **Shell Cleanup**: Removed zsh-specific duplication, improved POSIX shell compatibility

**Impact**:
- All default applications now managed from single YAML file (`globals.yaml`)
- XDG MIME type associations automatically synchronized with shell environment
- Changing default editor/browser requires single edit in `globals.yaml`
- Template-driven approach enables per-machine customization if needed
- Improved shell startup efficiency by removing redundant PATH configuration
- Total additions: 99 lines (34 globals.yaml + 40 login.tmpl + 25 mimeapps.list.tmpl)
- Fixed shell path reference bug improving POSIX shell compatibility

### Phase 11: Automated NVIDIA GPU Driver Configuration ✅
**Commit**: `245e628` - "Add automated NVIDIA GPU driver configuration with DKMS and Wayland support"

**Changes Made**:
- **New Configuration Script** (`.chezmoiscripts/run_once_before_007_configure_gpu_drivers.sh.tmpl` - 291 lines):
  - Comprehensive NVIDIA DKMS driver setup executed early in boot process (before file application)
  - **GPU Detection**: Automatically detects NVIDIA GPU via `lspci` (skips configuration if not found)
  - **Conflict Resolution**: Removes incompatible packages (old nvidia-dkms, nvidia-lts) before installation
  - **Package Installation** (7 packages in correct dependency order):
    - `dkms` - DKMS framework (must be installed first)
    - `linux-headers`, `linux-lts-headers` - Kernel headers for both kernels
    - `nvidia-open-dkms` - Open-source NVIDIA kernel modules (DKMS version)
    - `nvidia-utils` - NVIDIA userspace utilities
    - `nvidia-settings` - NVIDIA configuration GUI
    - `lib32-nvidia-utils` - 32-bit support for gaming/compatibility
  - **DKMS Module Management**:
    - Automatically builds modules for current kernel (`dkms autoinstall`)
    - Verifies modules are built and loaded via `dkms status`
  - **Initramfs Configuration**:
    - Creates `/etc/mkinitcpio.conf.d/nvidia.conf` with required modules
    - Loads: `nvidia nvidia_modeset nvidia_uvm nvidia_drm`
    - Keeps `kms` hook (required for DKMS early kernel mode setting)
    - Rebuilds initramfs only when configuration changes
  - **Kernel Parameter Configuration** (supports both boot methods):
    - **UKI (Unified Kernel Images)**: Updates `/etc/kernel/cmdline`
    - **Traditional systemd-boot**: Updates `/boot/loader/entries/*.conf`
    - Adds: `nvidia-drm.modeset=1 nvidia-drm.fbdev=1` (enables DRM kernel mode setting)
    - Creates backup files before modifications

- **Package Management Updates** (`.chezmoidata/packages.yaml`):
  - Moved NVIDIA drivers from `graphics_drivers` section to script-managed approach
  - Updated documentation (line 177-180): Clarifies drivers managed by `run_once_before_007` script
  - Rationale: Script ensures correct installation order and dependency handling
  - Benefits: Prevents conflicts, handles cleanup, configures initramfs/kernel parameters atomically

- **Package Manager Script Updates** (`run_once_before_001_install_package_manager.sh.tmpl`):
  - Added Chaotic-AUR repository configuration (community repository with precompiled packages)
  - Repository configuration: `/etc/pacman.conf` includes `[chaotic-aur]` section
  - Keyring packages: `chaotic-keyring`, `chaotic-mirrorlist` (added to system_software)
  - Benefits: Faster AUR package installation, reduced compilation time

- **Hyprland Environment Configuration** (`private_dot_config/hypr/conf/environment.conf`):
  - Enhanced NVIDIA-specific comments and documentation (76 lines total)
  - Clarified hardware video acceleration settings (`LIBVA_DRIVER_NAME=nvidia`)
  - Documented hardware cursor workaround (`WLR_NO_HARDWARE_CURSORS=1`)
  - Added note: "Test with value 0 on nvidia-open-dkms" (newer drivers may not need workaround)
  - VSync configuration: `__GL_SYNC_TO_VBLANK=1` (prevents screen tearing)
  - Improved comments explaining each variable's purpose and impact

**Architecture Overview**:
```
GPU Driver Configuration Flow:
1. run_once_before_007 (Early Setup)
   ├─→ Detect NVIDIA GPU (lspci)
   ├─→ Remove conflicting packages
   ├─→ Install DKMS + headers + nvidia-open-dkms
   ├─→ Build DKMS modules (dkms autoinstall)
   ├─→ Configure initramfs (nvidia.conf)
   ├─→ Add kernel parameters (cmdline or boot entry)
   └─→ Rebuild initramfs + UKI images

2. Hyprland environment.conf (Session Setup)
   ├─→ LIBVA_DRIVER_NAME=nvidia
   ├─→ GBM_BACKEND=nvidia-drm
   ├─→ __GLX_VENDOR_LIBRARY_NAME=nvidia
   ├─→ WLR_NO_HARDWARE_CURSORS=1
   └─→ __GL_SYNC_TO_VBLANK=1
```

**Rationale**:
- **DKMS Approach**: Kernel modules rebuild automatically on kernel updates (no manual intervention)
- **nvidia-open-dkms**: Open-source variant provides better Wayland support and community maintenance
- **Early Execution**: `run_once_before_007` runs before file application, ensuring drivers ready for desktop session
- **Idempotent Design**: Script safely re-runs if interrupted (checks existing state before modifications)
- **Dual Kernel Support**: Builds modules for both `linux` and `linux-lts` kernels
- **UKI Compatibility**: Handles both Unified Kernel Images and traditional boot entries
- **Chaotic-AUR**: Reduces compilation time for AUR packages on initial system setup

**Impact**:
- System now has complete automated NVIDIA GPU configuration for Wayland
- DKMS modules automatically rebuild on kernel updates (no manual intervention)
- Kernel parameters properly configured for DRM mode setting and fbdev support
- Initramfs includes all required NVIDIA modules for early KMS
- Hyprland session environment optimized for NVIDIA GPU acceleration
- Total configuration: 291 lines of automation + enhanced environment documentation
- Post-reboot verification workflow clearly documented
- Chaotic-AUR repository reduces AUR compilation time on fresh installations
- **⚠️ REBOOT REQUIRED** after initial setup for kernel parameters and modules to take effect

### Phase 12: Enhanced File Management with Dolphin and Yazi ✅
**Commit**: `fa46388` - "Enhance file management with Dolphin GUI integration and Yazi TUI file manager"

**Summary**: Added 14 packages across two new categories (file_management with 8 packages for Dolphin ecosystem, terminal_file_management with 3 packages for Yazi TUI). Created 5 configuration files integrating KDE terminal settings, hiding duplicate menu entries, and adding Hyprland keybindings. Enhanced MIME type associations with 13 new lines for directory and archive handling.

**Impact**: Complete dual file management system with GUI (Dolphin via Super+E) providing network protocol support and TUI (Yazi via Super+Shift+E) with vim keybindings and zoxide integration. Dolphin F4 embedded terminal and "Open Terminal Here" context menu launch ghostty via centralized configuration. Translucent windows and floating dialogs provide polished desktop experience.

### Phase 13: Enhance Waybar Status Bar with Interactive Controls ✅
**Commit**: `f555796` - "Refine Waybar styling with Nerd Fonts glyphs and improve file management"

**Summary**: Simplified Waybar by removing 3 redundant monitoring modules (CPU, memory, temperature - 93 lines). Enhanced network, audio, bluetooth, battery, and backlight modules with multi-click actions (62 new lines of interactivity). Added visual grouping system with rounded corners and module-specific hover effects (38 lines of styling). Implemented critical battery animation with smart charging detection.

**Impact**: Status bar transformed from passive information display to interactive control panel. Network module provides one-click access to nmtui, audio module launches pavucontrol or toggles mute, backlight supports instant presets (25/50/75%) with fine scroll adjustments. Visual polish with grouped modules, Material Design icons, and smooth transitions. More functionality with less visual clutter (net +42 lines).

### Phase 14: Enhanced Power Management and Session Controls ✅
**Commit**: `8eba322` - "Enhance power management and session controls with NVIDIA optimizations"

**Summary**: Consolidated service configuration script (63 lines) with enhanced Docker user group management and conditional NVIDIA power management for laptops. Fixed critical hybrid graphics issue preventing 1-minute Electron app delays. Enhanced session management with wlogout toggle script (40 lines), Material Design icons, and oksolar theming. Added VA-API hardware acceleration and updated cursor support for modern NVIDIA drivers.

**Impact**: Docker users get safe automatic group configuration with clear activation instructions. Intel+NVIDIA systems no longer experience Electron application startup stalls. Hardware-accelerated video works in browsers and media players. Professional power menu with 6 actions and toggle behavior accessible via Super+Shift+Q.

### Phase 15: Boot Experience and System Configuration ✅
**Commit**: `0cae940` - "Configure boot experience with Plymouth, SDDM, locale, and topgrade improvements"

**Summary**: Added Plymouth and SDDM configuration to globals.yaml (theme, display server settings). Created 5 comprehensive scripts totaling 870 lines: locale configuration (99 lines), SDDM theme installation (188 lines), Plymouth configuration (169 lines), SDDM service configuration (188 lines), and two dynamic update scripts (168 lines combined). Enhanced topgrade with flatpak sudo support and safe orphan removal.

**Impact**: Professional boot experience with visual consistency from Plymouth splash through SDDM login to Hyprland desktop. Graphical password prompt for encrypted partitions. European date format system-wide (en_GB.UTF-8). Native Wayland login session eliminates X11 dependency. Boot themes manageable from globals.yaml with automatic updates. **⚠️ REBOOT REQUIRED** after initial setup.

---

**Archive Note (Phases 10-15)**: These six phases completed the system configuration maturation, establishing centralized configuration management (globals.yaml), full hardware support (NVIDIA GPU drivers), dual file management (Dolphin + Yazi), interactive status bar controls, comprehensive power management, and professional boot experience. Phase 16 consolidates these scripts for improved maintainability. See [MIGRATION_LOG.md](./MIGRATION_LOG.md) for current migration status.
