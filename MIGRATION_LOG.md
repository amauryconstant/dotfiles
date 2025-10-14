# Arch Linux + Hyprland Migration Log

**Branch**: `arch-switch`
**Started**: October 2025
**Target**: Migrate from EndeavourOS + KDE Plasma to vanilla Arch Linux + Hyprland

## Migration Overview

This log documents the migration of dotfiles from an EndeavourOS-based KDE Plasma setup to a clean Arch Linux installation with Hyprland as the compositor.

**Historical Phases**: Phases 1-9 (EndeavourOS removal through NetworkManager configuration) have been archived to [MIGRATION_LOG_ARCHIVE.md](./MIGRATION_LOG_ARCHIVE.md).

## Migration History

**Note**: Phases 1-9 archived. See [MIGRATION_LOG_ARCHIVE.md](./MIGRATION_LOG_ARCHIVE.md) for:
- Phase 1: Remove Distribution Dependencies
- Phase 2: Archive KDE Configuration
- Phase 3: Document archinstall Baseline Packages
- Phase 4: Implement Hyprland Desktop Environment
- Phase 5: Migrate to ghostty and neovim
- Phase 6: Add Critical Security and Usability Components
- Phase 7: Add Comprehensive Hyprland Documentation
- Phase 8: Enhance Hyprland Desktop with Notifications and Keybinds
- Phase 9: Configure NetworkManager with iwd Backend

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

### Phase 11: Automated NVIDIA GPU Driver Configuration ✅
**Commit**: `b7505cb` - "Add automated NVIDIA GPU driver configuration with DKMS and Wayland support"

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
**Commit**: `e1dd48c` - "Enhance file management with Dolphin GUI integration and Yazi TUI file manager"

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

### Phase 13: Enhance Waybar Status Bar with Interactive Controls ⏳
**Commit**: `(pending)` - "Enhance Waybar status bar with interactive controls and visual refinements"

**Changes Made**:
- **Waybar Configuration Simplification** (`private_dot_config/waybar/config.tmpl`):
  - **Removed System Monitoring Modules** (3 modules, 93 lines removed):
    - Removed `cpu` module - Redundant with system monitors (btop, htop)
    - Removed `memory` module - Accessible via dedicated system monitoring tools
    - Removed `temperature` module - Available in full monitoring interfaces
    - Rationale: Status bar should show essential info, not duplicate full monitoring tools
  - **Enhanced Network Module** (14 new lines):
    - Multi-click actions for comprehensive network management:
      - Left-click: `ghostty -e nmtui` - NetworkManager TUI (primary action)
      - Right-click: `networkctl status` - Quick network status check
      - Middle-click: `nmcli connection reload` - Reload network connections
    - Enhanced tooltips with detailed technical info:
      - WiFi: ESSID, frequency, IP/CIDR, gateway, bandwidth (↓/↑)
      - Ethernet: IP/CIDR, gateway, bandwidth monitoring
      - Disconnected: Clear error message
    - Improved icons: Material Design icons (󰈀 ethernet, 󰖪 disconnected)
    - Optimized update interval: 5 seconds (balanced monitoring)
    - Alternate format: Click to toggle IP address display
  - **Enhanced PulseAudio Module** (20 new lines):
    - Multi-click actions for complete audio control:
      - Left-click: `pavucontrol` - Full volume control GUI
      - Right-click: `pamixer -t` - Quick mute toggle
      - Middle-click: `pamixer --next-sink` - Switch audio output device
    - Scroll actions: Fine-grained volume control (±5% per scroll)
    - Device-specific icons: Headphone (󰋋), Headset (󰋎), Speaker levels
    - Material Design volume icons: 󰕿 (low), 󰖀 (medium), 󰕾 (high)
    - Bluetooth audio support: `format-bluetooth` and `format-bluetooth-muted`
    - Enhanced tooltip: Sink description, volume %, source info
    - Conditional execution: `exec-if "which pamixer"` (only load if available)
  - **Enhanced Bluetooth Module (Laptop)** (4 new lines):
    - Material Design icons: 󰂯 (enabled), 󰂲 (disabled)
    - 11-level battery icons for connected devices (󰥇-󰥈)
    - Conditional execution: `exec-if "which blueman-manager"`
    - Click action: Launch Blueman Manager GUI
  - **Enhanced Battery Module (Laptop)** (15 new lines):
    - Material Design icon set (11 icons: 󰁺-󰁹)
    - Multi-state icons: Charging (󰢜), charging-full (󰂋), plugged (󰚥), full (󰁹)
    - Multi-click actions:
      - Left-click: `powerprofilesctl` - Power profile selector
      - Right-click: Battery info notification via upower
    - Alternate format: Toggle between percentage and time remaining
    - Optimized update interval: 3 seconds (responsive monitoring)
    - Enhanced tooltip: Time remaining, power draw (W), battery health (%)
    - Adjusted thresholds: Good (100%), Warning (30%), Critical (10%)
  - **Enhanced Backlight Module (Laptop)** (13 new lines):
    - Switched from `brightnessctl` to `light` (simpler, more direct control)
    - Multi-click actions for quick brightness presets:
      - Left-click: 25% brightness
      - Right-click: 75% brightness
      - Middle-click: 50% brightness
    - Fine-grained scroll control: ±1% adjustments (smooth transitions)
    - Conditional execution: `exec-if "which light"`
    - Responsive update interval: 2 seconds
    - 9-level brightness icons (empty to full progression)

- **Waybar Styling Enhancements** (`private_dot_config/waybar/style.css.tmpl`):
  - **Visual Grouping System** (38 new lines):
    - Created unified module group: network, pulseaudio, backlight, battery
    - Rounded corner design: First module (8px left), last module (8px right)
    - Zero margins between modules for visual continuity
    - Increased padding: 12px (improved clickability and aesthetics)
  - **Enhanced Hover Effects**:
    - Module-specific semi-transparent backgrounds (10% opacity):
      - Network: Cyan tint `rgba(37, 157, 148, 0.1)`
      - PulseAudio: Violet tint `rgba(108, 113, 195, 0.1)`
      - Backlight: Yellow tint `rgba(182, 136, 0, 0.1)`
      - Battery: Green tint `rgba(129, 149, 0, 0.1)`
    - Smooth transitions: `0.2s ease` for all hover state changes
  - **Workspace Button Improvements**:
    - Enhanced hover: Blue background (primary accent) with high-contrast text
    - Consistent active state: Matches hover colors for unified experience
    - Smooth transitions: `all 0.2s ease`
  - **Enhanced Battery Animations** (20 new lines):
    - Critical battery animation: `@keyframes critical-blink`
      - Background flashes red at 50% keyframe
      - Text alternates between red on transparent and white on red
      - 1 second interval, infinite loop, linear timing
    - State-specific transitions: Smooth color/background changes (0.3s ease)
    - Smart charging detection: Warning/critical colors only when not charging

- **Project Organization** (`.chezmoiignore`):
  - Restructured ignore patterns with clear section comments
  - Moved markdown exclusion to specific pattern: `./*.md` (only root level)
  - Added new `.resources/` directory for project assets (glyphnames.json)
  - Organized sections: Chezmoi internals, development files, archives, resources

**Architecture Improvements**:
```
Enhanced Waybar Status Bar:
├─→ Left: Hyprland workspaces + window title
├─→ Center: Clock with calendar tooltip
└─→ Right: Visual module group
    ├─→ System Tray (Nextcloud, system icons)
    ├─→ Network (multi-click: TUI, status, reload)
    ├─→ [Bluetooth] (laptop only, GUI manager)
    ├─→ [Backlight] (laptop only, preset clicks + scroll)
    ├─→ [Battery] (laptop only, power profiles + info)
    └─→ PulseAudio (multi-click: GUI, mute, switch sink)

Interactive Control Flow:
Network Module → Left: nmtui, Right: status, Middle: reload
Audio Module → Left: pavucontrol, Right: mute, Middle: next sink, Scroll: ±5%
Backlight Module → Left: 25%, Right: 75%, Middle: 50%, Scroll: ±1%
Battery Module → Left: power profiles, Right: info notification
```

**Rationale**:
- **Simplified Information**: Removed redundant CPU/memory/temp (accessible via btop/htop)
- **Enhanced Interactivity**: Multi-click actions provide quick access to common tasks
- **Visual Polish**: Grouped modules with rounded corners and hover effects improve aesthetics
- **Responsive Controls**: Fine-grained scroll adjustments (1% brightness, 5% volume)
- **Quick Presets**: Backlight click actions provide instant brightness levels
- **Material Design**: Consistent icon set across all modules (modern, recognizable)
- **Smart Feedback**: Enhanced tooltips with technical details for troubleshooting
- **Battery Intelligence**: Conditional animations (only flash when not charging)
- **Ergonomic Design**: Increased padding (12px) improves click target size
- **Tool Consolidation**: Uses `light` instead of `brightnessctl` (simpler, direct control)
- **Conditional Loading**: Modules only load if required tools are available (`exec-if`)

**Impact**:
- Cleaner status bar focusing on essential, actionable information
- Network management: One click to nmtui, right-click for quick status
- Audio control: Full GUI (pavucontrol) or quick actions (mute, switch sink)
- Brightness control: Instant presets (25/50/75%) or fine scroll adjustments
- Power management: Quick access to power profiles and battery details
- Visual cohesion: Grouped modules with consistent styling and hover effects
- Professional appearance: Material Design icons and polished animations
- Enhanced UX: Larger click targets, smooth transitions, intuitive interactions
- Battery safety: Animated critical warning (background flash) only when not charging
- Responsive monitoring: Optimized update intervals (2s backlight, 3s battery, 5s network)
- Total changes: 135 lines added (interactivity + styling), 93 lines removed (redundant monitors)
- Net impact: More functionality with less visual clutter

---

## Next Steps

---

**Last Updated**: 2025-10-14
