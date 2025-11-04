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
**Commit**: `45f786a` - "Consolidate configuration scripts and update migration log"

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
**Commit**: `81f1196` - "Implement dynamic wallpaper rotation with wallust color palette integration"

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

### Phase 18: Omarchy-Inspired Desktop Enhancement and Hierarchical Menu System ✅
**Commit**: `(pending)` - "Implement Omarchy-inspired desktop utilities with hierarchical menu system"

**Changes Made**:
- **Script Organization Restructure** (35 files reorganized):
  - **New Directory Structure**: Organized scripts by functional category
    - `desktop/` (8 files): Desktop utilities and window management
    - `media/` (3 files): Screenshots, wallpapers, recording
    - `menu/` (10 files): Hierarchical menu system
    - `system/` (1 file): System-level utilities
    - `terminal/` (1 file): Terminal-specific utilities
    - `utils/` (1 file): General utility functions
  - **Benefits**: Logical grouping, easier maintenance, clearer purpose

- **Enhanced Desktop Utilities** (8 new scripts in `desktop/`):
  - **`launch-or-focus.sh`**: Single-instance application behavior (focus existing or launch new)
  - **`audio-switch.sh`**: Cycle through audio outputs with visual feedback and swayosd integration
  - **`screenrecord.sh`**: GPU-accelerated screen recording with audio support and toggle functionality
  - **`nightlight-toggle.sh`**: Blue light filter control using hyprsunset (6000K ↔ 4000K)
  - **`idle-toggle.sh`**: Toggle automatic screen locking for presentation mode
  - **`waybar-toggle.sh`**: Show/hide status bar for distraction-free mode
  - **`workspace-gaps-toggle.sh`**: Toggle gaps and borders for immersive/presentation mode
  - **`keybindings.sh`**: Renamed from keybinds_cheatsheet.sh (consistency)

- **Advanced Media Handling** (3 scripts in `media/`):
  - **`screenshot.sh`**: Smart screenshot system with Satty annotation editor
    - **Smart mode**: Auto-snaps to window if tiny selection, region selection with wayfreeze
    - **Multiple modes**: smart, region, windows, fullscreen, clipboard-direct
    - **Integration**: wayfreeze for clean captures, satty for annotation, hyprpicker for colors
  - **`random-wallpaper.sh`**: Moved from root (media category)
  - **`set-wallpaper.sh`**: Moved from root (media category)

- **Hierarchical Menu System** (10 scripts in `menu/`):
  - **`system-menu.sh`**: Main entry point with 10 categories (Apps, Learn, Trigger, Style, Setup, Install, Remove, Update, About, System)
  - **`menu-helpers.sh`**: Shared utilities (show_menu, confirm, notify, run_command)
  - **`menu-trigger.sh`**: Quick actions (Capture, Share, Toggle) with submenus
  - **`menu-install.sh`**: Package installation with category selection
  - **`menu-remove.sh`**: Package removal interface
  - **`menu-update.sh`**: System update options (topgrade, package managers)
  - **`menu-setup.sh`**: System configuration utilities
  - **`menu-style.sh`**: Theme and appearance settings
  - **`menu-learn.sh`**: Help and documentation access
  - **`menu-system.sh`**: Power management and system controls

- **Terminal Enhancement** (1 script in `terminal/`):
  - **`terminal-cwd.sh`**: Detect current terminal's working directory for spawning new terminals in same location
  - **Integration**: Enhanced Super+Return binding to preserve CWD across terminal launches

- **Package Management Updates**:
  - **New AUR packages**: `hyprsunset`, `grim`, `slurp`, `satty`, `wayfreeze`, `gpu-screen-recorder`, `swayosd`, `localsend`, `xkeyboard-config`
  - **New category**: `wayland_utilities` for screenshot, recording, and display tools
  - **Updated paths**: All script references updated to new directory structure

- **Hyprland Keybinding Enhancements** (`bindings.conf.tmpl`):
  - **Safety improvements**: Removed dangerous Super+M exit binding, added safety warnings
  - **Enhanced terminal**: Super+Return now preserves current working directory
  - **Single-instance apps**: Super+E uses launch-or-focus for file manager
  - **Advanced screenshots**: Print Screen opens Satty editor, Shift+Print for quick clipboard
  - **New utility bindings**: Super+R (record), G (gaps), A (audio), N (nightlight), I (idle), B (waybar), T (monitor)
  - **Menu system**: Super+Space for main menu, Super+Alt+S/T for quick access
  - **Color picker**: Super+Print for hyprpicker integration

**Architecture**:
```
Hierarchical Menu System (Super+Space):
├─→ Apps (wofi --show drun)
├─→ Learn (help/documentation)
├─→ Trigger (quick actions)
│   ├─→ Capture (screenshots, recording, color picker)
│   ├─→ Share (file/clipboard sharing - placeholder)
│   └─→ Toggle (nightlight, idle, waybar, gaps)
├─→ Style (theme/appearance)
├─→ Setup (system configuration)
├─→ Install (package installation)
├─→ Remove (package removal)
├─→ Update (system updates)
├─→ About (system information)
└─→ System (power management)

Enhanced Desktop Utilities:
├─→ Single-instance behavior (launch-or-focus)
├─→ Audio management with OSD (audio-switch)
├─→ GPU recording with toggle (screenrecord)
├─→ Blue light control (nightlight-toggle)
├─→ Presentation mode (idle-toggle, gaps-toggle)
└─→ UI controls (waybar-toggle)

Advanced Media System:
├─→ Smart screenshots with annotation (screenshot.sh + satty)
├─→ Screen freeze for clean captures (wayfreeze)
├─→ Color picker integration (hyprpicker)
└─→ Organized media scripts directory
```

**Rationale**:
- **Omarchy Inspiration**: Adapted proven desktop patterns from Omarchy for enhanced productivity
- **Hierarchical Organization**: Logical script categorization improves maintainability and discoverability
- **Single-Instance Behavior**: Prevents multiple application instances, improves workflow consistency
- **Advanced Media Handling**: Professional screenshot tools with annotation and smart selection
- **Menu-Driven Interface**: Reduces keybinding memorization while maintaining power-user efficiency
- **Safety First**: Removed dangerous bindings, added confirmation dialogs for critical actions
- **Visual Feedback**: OSD notifications, swayosd integration, consistent user experience
- **Presentation Mode**: Comprehensive tools for distraction-free work and presentations

**Impact**:
- **Script organization**: 35 files reorganized into 6 logical directories
- **New desktop utilities**: 8 enhanced scripts for better workflow management
- **Menu system**: 10-script hierarchical interface for system control
- **Enhanced keybindings**: 15+ new keybindings for desktop utilities
- **Package additions**: 9 new AUR packages for advanced functionality
- **Safety improvements**: Removed dangerous exit binding, added confirmation flows
- **User experience**: Consistent notifications, visual feedback, intuitive organization
- **Productivity**: Single-instance apps, smart screenshots, quick toggle utilities
- **Total new functionality**: 1,208 lines of new automation and utilities
- **Net change**: +1,179 lines (significant feature addition)

---

### Phase 19: Hyprland Keybinding Fixes and Fullscreen Dispatcher Resolution ✅
**Commit**: `(pending)` - "Fix Hyprland fullscreen dispatcher syntax and resolve configuration parser errors"

**Changes Made**:
- **Fullscreen Dispatcher Investigation**:
  - **Issue**: Configuration parser rejected `fullscreen 0` and `fullscreen 1` despite `hyprctl dispatch` working correctly
  - **Research**: Consulted official Hyprland documentation to verify correct dispatcher syntax
  - **Testing**: Manual verification confirmed `hyprctl dispatch fullscreen 0` and `fullscreen 1` work as expected
  - **Root Cause**: Configuration parser syntax requirements differ from runtime dispatch commands

- **Syntax Resolution**:
  - **Applied Fix**: Changed from `fullscreen 0`/`fullscreen 1` to `fullscreen` (toggle) and `fullscreen 1` (maximize)
  - **Parser Compliance**: Configuration now accepts syntax while maintaining intended functionality
  - **Validation**: `hyprctl configerrors` shows no parsing errors after fix
  - **Functionality Preserved**: Both toggle and maximize fullscreen behaviors work correctly

- **Keybinding Organization Completion**:
  - **Completed Reorganization**: Finished keybinding improvements that were blocked by fullscreen issue
  - **Verified All Bindings**: Confirmed all keybindings work as intended after syntax fix
  - **Configuration Reload**: Successfully applied changes with `hyprctl reload`

**Rationale**:
- **Documentation-Driven Fix**: Used official Hyprland docs to resolve parser vs runtime discrepancy
- **Pragmatic Solution**: Chose syntax that satisfies both parser requirements and functional needs
- **System Stability**: Resolved configuration errors that could affect Hyprland startup
- **User Experience**: Maintained intended fullscreen behavior while fixing technical issues

**Impact**:
- **Configuration Stability**: Eliminated parser errors that could cause startup issues
- **Keybinding Reliability**: All fullscreen keybindings now work consistently
- **Documentation Alignment**: Configuration matches official Hyprland dispatcher syntax
- **Unblocked Development**: Resolved blocker for keybinding organization improvements
- **Minimal Changes**: Focused fix with no disruption to existing functionality

---

## Next Steps

---

**Last Updated**: 2025-11-04
