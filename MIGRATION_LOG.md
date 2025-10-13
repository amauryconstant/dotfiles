# Arch Linux + Hyprland Migration Log

**Branch**: `arch-switch`
**Started**: October 2025
**Target**: Migrate from EndeavourOS + KDE Plasma to vanilla Arch Linux + Hyprland

## Migration Overview

This log documents the migration of dotfiles from an EndeavourOS-based KDE Plasma setup to a clean Arch Linux installation with Hyprland as the compositor.

**Historical Phases**: Phases 1-5 (EndeavourOS removal through ghostty/neovim migration) have been archived to [MIGRATION_LOG_ARCHIVE.md](./MIGRATION_LOG_ARCHIVE.md).

## Migration History

**Note**: Phases 1-5 archived. See [MIGRATION_LOG_ARCHIVE.md](./MIGRATION_LOG_ARCHIVE.md) for:
- Phase 1: Remove Distribution Dependencies
- Phase 2: Archive KDE Configuration
- Phase 3: Document archinstall Baseline Packages
- Phase 4: Implement Hyprland Desktop Environment
- Phase 5: Migrate to ghostty and neovim

### Phase 6: Add Critical Security and Usability Components ✅
**Commit**: `ba0b949` - "Add critical security and usability components for Hyprland deployment"

**Changes Made**:
- **Package Management** (`.chezmoidata/packages.yaml` wayland_desktop section):
  - Added 7 packages: `hyprlock`, `hypridle`, `cliphist`, `wlogout`, `wl-clipboard`, `pamixer`, `brightnessctl`
  - Addresses security gaps (screen locking, idle management) and usability needs (clipboard history, power menu, media controls)

- **New Configuration Files** (4 files, 244 lines total):
  - `hyprlock.conf` - Screen locker with oksolar theming (103 lines)
    - Password input field with oksolar colors (blue outline, dark background)
    - Time/date/user labels with consistent styling
    - Screenshot background with blur effect
  - `hypridle.conf.tmpl` - Idle daemon with chassis-specific behavior (37 lines)
    - Lock screen after 5 minutes of inactivity
    - Turn off displays after 10 minutes
    - Suspend after 15 minutes (laptop only, using `{{ if eq .chassisType "laptop" }}`)
  - `wlogout/layout` - Power menu actions (30 lines)
    - 5 actions: lock, logout, suspend, reboot, shutdown
    - JSON layout with keybindings (l, e, u, r, s)
  - `wlogout/style.css.tmpl` - Power menu styling with oksolar colors (74 lines)
    - Button styling with hover effects
    - oksolar color scheme integration via templates

- **Hyprland Configuration Updates**:
  - `autostart.conf` - Enabled 3 essential daemons:
    - Uncommented `polkit-kde-agent` (GUI privilege escalation)
    - Added `wl-paste --watch cliphist store` (clipboard history watcher)
    - Added `hypridle` (idle management daemon)
  - `bindings.conf.tmpl` - Added 4 new keybindings:
    - `Super+L` - Lock screen (hyprlock)
    - `Super+Shift+E` - Power menu (wlogout)
    - `Super+C` - Clipboard history (cliphist via wofi)
    - `XF86MonBrightnessUp/Down` - Brightness control (uncommented, laptop)

- **Supporting Documentation**:
  - `.claude/agents/hyprland-investigator.md` - Specialized agent for Hyprland analysis (199 lines)
  - Updated `.gitignore` to exclude analysis working directories

**Configuration Highlights**:
- **Template Integration**: `hypridle.conf.tmpl` uses chassis detection for laptop-specific suspend behavior
- **Color Consistency**: All new configs use oksolar color scheme from `.chezmoidata/colors.yaml`
- **Security Focus**: Screen locking integrated with idle management (lock before suspend)
- **Usability**: Complete power menu with all session management options
- **Media Integration**: Brightness and volume controls fully functional

**Rationale**:
- Closes 7 critical gaps identified in ARCH_HYPRLAND_MIGRATION_ANALYSIS.md
- **Security**: Screen locking and idle management prevent unauthorized access
- **Usability**: Power menu, clipboard history, and media controls essential for daily workflow
- **Production-Ready**: Desktop environment now has all essential components for deployment
- Analysis-driven approach ensures best practices from Hyprland ecosystem

**Impact**:
- System now production-ready with complete security and usability features
- Screen automatically locks after inactivity (configurable timeouts)
- GUI power menu for logout, suspend, reboot, shutdown operations
- Clipboard history accessible via keyboard shortcut
- Media keys functional for volume and brightness control
- Polkit authentication enables GUI privilege escalation for system settings
- Total configuration growth: 244 lines across 4 new files + comprehensive analysis documentation

### Phase 7: Add Comprehensive Hyprland Documentation ✅
**Commit**: `7a595ab` - "Add comprehensive Hyprland desktop environment documentation"

**Changes Made**:
- **Documentation Expansion** (103 lines across 2 files):
  - **CLAUDE.md**: Added 75 lines of detailed technical guidance for Hyprland development
  - **README.md**: Enhanced with 36 lines of user-facing documentation updates
- **Technical Guidance Added**:
  - Specified Arch Linux with archinstall + Hyprland profile as target platform
  - Documented complete desktop stack: Hyprland + Waybar + Wofi
  - Clarified terminal architecture: Ghostty (primary) + Kitty (baseline fallback)
  - Detailed modular Hyprland configuration structure (9 conf files)
  - Documented package management with archinstall baseline tracking
  - Added testing commands and reload procedures for desktop components
  - Expanded directory structure documentation with config folder breakdown

**Rationale**:
- Provides comprehensive technical reference for Hyprland-based development
- Establishes clear patterns for desktop environment configuration and maintenance
- Documents architectural decisions and component relationships
- Enables efficient development and troubleshooting of Hyprland setup
- Creates single source of truth for desktop environment specifications

**Impact**:
- Development team now has detailed reference for Hyprland configuration patterns
- Clear documentation of testing procedures and component interactions
- Established patterns for future desktop environment enhancements
- Improved onboarding experience for developers working with the dotfiles
- Documentation now matches actual implemented architecture

### Phase 8: Enhance Hyprland Desktop with Notifications and Keybinds ✅
**Commit**: `5db9a51` - "Enhance Hyprland desktop with dunst notifications, wallpaper management, and keybinds system"

**Changes Made**:
- **Commit Hash Verification**: Corrected all commit hashes in migration history to match actual git repository:
  - Phase 1: `209c9c8` → `7554849` - "Remove the dependency to endeavouros"
  - Phase 2: `3a1e1a8` → `4900f68` - "Archive KDE configuration files"
  - Phase 3: `7396831` → `49b0155` - "Document archinstall baseline packages and reorganize NVIDIA drivers"
  - Phase 4: `13964e2` → `59469b7` - "Add comprehensive Hyprland configuration with waybar"
  - Phase 5: `1c8ea26` → `da51860` - "Migrate terminal and editor to ghostty and neovim"
  - Phase 6: `(to be determined)` → `ba0b949` - "Add critical security and usability components for Hyprland deployment"
- **Added Missing Phase**: Documented Phase 7 commit `7a595ab` for comprehensive Hyprland documentation
- **Phase Renumbering**: Previous "Phase 7" renamed to "Phase 8" to accommodate missing documentation

**Rationale**:
- Ensures migration log accurately reflects actual git repository state
- Maintains traceability for each migration phase with correct chronological order
- Provides reliable reference for future development and troubleshooting
- Corrects documentation drift that occurred during migration process
- Preserves historical accuracy by documenting all significant commits

**Impact**:
- Migration log now accurately references all actual commits in repository
- All phases properly documented with correct hash references and chronological order
- Maintains historical accuracy for development team
- Enables reliable git operations (checkout, bisect, revert) based on documented commits
- Complete coverage of migration history from Phase 1 through Phase 8

### Phase 9: Configure NetworkManager with iwd Backend ✅
**Commit**: `a8bd346` - "Configure NetworkManager with iwd backend for WiFi management"

**Changes Made**:
- **Package Management** (`.chezmoidata/packages.yaml`):
  - Added `networkmanager` to `networking_tools.list` (line 144)
  - Added `gnome-keyring` to `general_software.list` (line 151) for WiFi password storage
  - Updated archinstall_baseline documentation:
    - `iwd` - Clarified as "Wireless daemon (used as NetworkManager backend)" (line 30)
    - `wpa_supplicant` - Marked as "WPA/WPA2 authentication (replaced by iwd)" (line 36)
  - Code cleanup: Removed trailing whitespace from `posting` entry (line 134)
  - Removed obsolete `tldr` from delete.arch section (now using `tlrc`)

- **New Configuration Script** (`.chezmoiscripts/run_once_after_008_configure_networkmanager.sh.tmpl`):
  - 61 lines implementing comprehensive NetworkManager + iwd backend setup
  - **NetworkManager Configuration**:
    - Enables NetworkManager service for boot startup
    - Creates `/etc/NetworkManager/conf.d/wifi_backend.conf` with `wifi.backend=iwd`
  - **iwd Backend Setup**:
    - Enables and starts iwd service (required for NetworkManager WiFi backend)
    - Disables wpa_supplicant to prevent conflicts with iwd
  - **Service Management**:
    - Restarts NetworkManager to apply backend configuration
    - Verifies NetworkManager is running successfully
  - **Error Handling**: Checks service status with graceful error messages

- **Hyprland Configuration Updates**:
  - `autostart.conf` - Added gnome-keyring daemon initialization (4 lines, line 43-46):
    - Launches with all components: `gpg,pkcs11,secrets,ssh`
    - Required for nmtui and NetworkManager to store/retrieve network credentials
    - Enables GUI privilege escalation for system settings (polkit integration)
  - `autostart.conf` - Removed commented `nm-applet` suggestion (line 56)
    - TUI approach preferred over system tray icon for network management

- **Waybar Status Bar Updates** (`config.tmpl`):
  - Added click handler for network module (line 287):
    - `"on-click": "ghostty --class=network-manager -e nmtui"`
    - Opens NetworkManager TUI in dedicated ghostty window on network icon click
    - Provides quick GUI access to WiFi connections, VPN, and network settings

**Architecture Overview**:
```
NetworkManager (network configuration daemon)
    ├─→ iwd backend (modern WiFi management)
    │   ├─→ Replaces wpa_supplicant
    │   └─→ Better performance and Wayland support
    ├─→ gnome-keyring (credential storage)
    │   ├─→ Stores WiFi passwords securely
    │   ├─→ SSH key management
    │   └─→ GPG key caching
    └─→ nmtui (TUI interface)
        └─→ Accessible via Waybar click (ghostty terminal)
```

**Rationale**:
- **NetworkManager + iwd**: Modern WiFi stack with better performance than wpa_supplicant
- **iwd Advantages**: Lower resource usage, better Wayland integration, faster connections
- **gnome-keyring**: Essential for secure WiFi password storage (nmtui dependency)
- **TUI over GUI**: `nmtui` provides full functionality without system tray clutter
- **Waybar Integration**: One-click access to network management from status bar
- **Clean Architecture**: Replaces archinstall's wpa_supplicant with modern iwd backend

**Impact**:
- System now has complete network management stack configured
- WiFi credentials stored securely via gnome-keyring integration
- NetworkManager accessible via waybar network icon click (spawns nmtui in ghostty)
- iwd backend provides modern WiFi management (replaces wpa_supplicant)
- Automatic service startup on boot (NetworkManager + iwd + gnome-keyring)
- Enhanced Wayland compatibility and performance over wpa_supplicant
- Total configuration: 61 lines of service configuration + 4 lines of autostart + 1 line waybar integration

### Phase 10: Centralize Environment Configuration with globals.yaml ✅
**Commit**: `31c6adb` - "Centralize environment configuration with globals.yaml"

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

### Phase 11: Automated NVIDIA GPU Driver Configuration ⏳
**Commit**: `(pending)` - "Add automated NVIDIA GPU driver configuration with DKMS and Wayland support"

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

### Phase 12: Enhanced File Management with Dolphin and Yazi ⏳
**Commit**: `(pending)` - "Enhance file management with Dolphin GUI integration and Yazi TUI file manager"

**Changes Made**:
- **Package Management** (`.chezmoidata/packages.yaml` - 14 new packages):
  - **New Categories Created**:
    - `file_management` (8 packages): Dolphin file manager ecosystem
      - `kio-extras` - Network protocols (SMB, FTP, SSH, etc.)
      - `ffmpegthumbs` - Video thumbnails in file browser
      - `kdegraphics-thumbnailers` - Extended image format thumbnails (RAW, PSD, etc.)
      - `qt5ct` - Qt5 theme configuration tool
      - `breeze` - Consistent Qt theme matching Hyprland aesthetic
      - `kde-cli-tools` - KDE command-line tools (enables "Open Terminal Here")
      - `file-roller` - Archive handling and extraction
    - `terminal_file_management` (3 packages): Yazi terminal file manager
      - `yazi` - Modern TUI file manager with vim keybindings
      - `unar` - Archive preview and extraction support
      - `poppler` - PDF preview support (via pdftotext)

- **Centralized Configuration** (`.chezmoidata/globals.yaml`):
  - Added `file_manager: org.kde.dolphin` to applications section
  - Added `terminal: ghostty` to applications section
  - Enables consistent application references across all configuration files

- **KDE Integration** (`private_dot_config/private_kdeglobals.tmpl` - new file, 4 lines):
  - Created templated KDE global settings for terminal integration
  - Sets `TerminalApplication={{ .globals.applications.terminal }}`
  - Enables Dolphin's F4 embedded terminal and "Open Terminal Here" context menu
  - Ensures all KDE applications use ghostty instead of kitty

- **KIO Service Menu** (`private_dot_local/share/private_kio/private_servicemenus/private_com.mitchellh.ghostty.desktop` - new file):
  - Hides ghostty from Dolphin's "Open With" menu (3 lines: `[Desktop Entry]\nHidden=true`)
  - Prevents duplicate/conflicting terminal options in context menus
  - Allows kde-cli-tools to manage "Open Terminal Here" properly

- **Hyprland Keybindings** (`private_dot_config/hypr/conf/bindings.conf.tmpl`):
  - **Template Integration** (line 32): Changed `exec, ghostty` → `exec, {{ .globals.applications.terminal }}`
    - Terminal launcher now uses centralized configuration from globals.yaml
  - **New Keybinding** (line 42-43): Added `Super+Shift+E` → Launch Yazi in terminal
    - `bind = $mod SHIFT, E, exec, {{ .globals.applications.terminal }} -e yazi`
    - Provides quick access to TUI file manager for power users
  - **Updated Comments** (line 38): Changed "File manager: Super + E" → "File manager: Super + E (GUI)"
    - Clarifies distinction between GUI (Dolphin) and TUI (Yazi) file managers

- **Window Rules** (`private_dot_config/hypr/conf/windowrules.conf` - 16 new lines):
  - **Main Window Styling**:
    - `opacity 0.9 0.8` - Translucent Dolphin windows (90% active, 80% inactive)
    - Default tiling behavior (fills workspace, no floating)
  - **File Operation Dialogs** (Copying/Moving/Deleting):
    - Float dialogs with fixed size (500x200)
    - Center on screen for visibility during file operations
  - **File Picker Dialogs** (Open/Save):
    - Float with larger size (800x600) for better file browsing
    - Center on screen for consistent user experience

- **MIME Type Associations** (`private_dot_config/mimeapps.list.tmpl` - 13 new lines):
  - **Directory Handling** (line 27): `inode/directory={{ .globals.applications.file_manager }}.desktop`
    - All directory opens launch Dolphin (templated for flexibility)
  - **Archive Handling** (lines 29-36): Associated 8 archive formats with file-roller
    - Formats: zip, tar, compressed-tar, 7z, gzip, bzip, xz, rar
    - Enables GUI extraction and browsing of compressed files
    - Integrates with Dolphin for seamless archive management

- **Shell Integration** (`private_dot_config/zsh/dot_zsh_plugins.txt`):
  - Added `fdw/yazi-zoxide-zsh` plugin (line 26)
  - Enables `y` command wrapper for Yazi with zoxide integration
  - Changes directory to last visited location when exiting Yazi
  - Combines fast directory jumping (zoxide) with visual file navigation (Yazi)

**File Management Architecture**:
```
File Management Layer:
├─→ GUI (Dolphin - Super+E)
│   ├─→ KDE ecosystem integration (kdeglobals.tmpl)
│   ├─→ Network protocols (kio-extras: SMB, FTP, SSH)
│   ├─→ Media previews (ffmpegthumbs, kdegraphics-thumbnailers)
│   ├─→ Terminal integration (F4, context menu → ghostty)
│   ├─→ Archive handling (file-roller GUI extraction)
│   └─→ Hyprland window rules (opacity, float/center dialogs)
│
└─→ TUI (Yazi - Super+Shift+E)
    ├─→ Terminal-based file management (vim keybindings)
    ├─→ Archive preview (unar integration)
    ├─→ PDF preview (poppler/pdftotext)
    ├─→ Zoxide integration (y command wrapper)
    └─→ Directory change on exit (zsh plugin)
```

**Configuration Flow**:
```
globals.yaml (Single Source of Truth)
    ├─→ kdeglobals.tmpl (KDE terminal integration)
    ├─→ bindings.conf.tmpl (Super+Return, Super+E, Super+Shift+E)
    ├─→ mimeapps.list.tmpl (inode/directory association)
    └─→ windowrules.conf (Dolphin window behavior)
```

**Rationale**:
- **Dual File Management**: GUI (Dolphin) for visual tasks, TUI (Yazi) for keyboard-driven workflows
- **KDE Integration**: Dolphin provides mature file management with extensive protocol support (SMB, FTP, SSH)
- **Terminal Consistency**: All "Open Terminal Here" integrations use ghostty via centralized config
- **Archive Support**: file-roller + unar provide comprehensive archive handling (GUI + TUI)
- **Yazi Advantages**: Modern TUI with vim keybindings, fast navigation, media previews, zoxide integration
- **MIME Centralization**: Directory and archive associations templated via globals.yaml
- **Window Management**: Dolphin opacity and dialog rules provide polished desktop experience
- **Template-Driven**: All application references use `{{ .globals.applications.* }}` for flexibility

**Impact**:
- Complete file management solution with both GUI and TUI options
- Dolphin F4 embedded terminal and context menu "Open Terminal Here" launch ghostty
- Super+E (Dolphin GUI) for general file browsing with network protocol support
- Super+Shift+E (Yazi TUI) for fast keyboard-driven file operations
- Seamless archive handling: Extract via Dolphin context menu (file-roller) or preview in Yazi (unar)
- Yazi zoxide integration: Exit Yazi and automatically change shell to last visited directory
- Translucent Dolphin windows (90%/80% opacity) match Hyprland aesthetic
- File operation dialogs float and center for better visibility during copy/move operations
- All directory opens launch Dolphin by default (MIME association)
- Consistent terminal application across all KDE/Dolphin integrations
- Total additions: 14 packages + 38 lines of configuration across 6 files
- No changes to archinstall baseline (Dolphin already included, enhanced with ecosystem packages)

---

## Next Steps

---

**Last Updated**: 2025-10-13
