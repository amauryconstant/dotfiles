# Arch Linux + Hyprland Migration Log

**Branch**: `arch-switch`
**Started**: October 2025
**Target**: Migrate from EndeavourOS + KDE Plasma to vanilla Arch Linux + Hyprland

## Migration Overview

This log documents the migration of dotfiles from an EndeavourOS-based KDE Plasma setup to a clean Arch Linux installation with Hyprland as the compositor.

## Migration History

### Phase 1: Remove Distribution Dependencies ✅
**Commit**: `f257929` - "Remove the dependency to endeavouros"

**Changes Made**:
- Deleted `.chezmoiscripts/run_once_before_004_install_distributions_and_os_specifics.sh.tmpl`
  - This script contained EndeavourOS-specific setup and welcome screen configuration
  - No longer needed for vanilla Arch installation
- Renumbered subsequent `run_once_before_*` scripts (005→004, 006→005, 007→006)
- Added NVIDIA driver packages to `packages.yaml`:
  ```yaml
  graphics_drivers:
    strategy: *_install_binary
    list:
      - nvidia-open        # Open-source NVIDIA kernel modules
      - nvidia-utils       # NVIDIA userspace utilities
      - nvidia-settings    # Configuration GUI
      - lib32-nvidia-utils # 32-bit support for gaming
      - nvidia-hook        # Automatic initramfs rebuild on driver updates
  ```

**Impact**: System now installs directly on vanilla Arch without EndeavourOS-specific dependencies.

### Phase 2: Archive KDE Configuration ✅
**Commit**: `0f86a8c` - "Archive KDE configuration files"

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
**Commit**: `3471fa7` - "Document archinstall baseline packages and reorganize NVIDIA drivers"

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
**Commit**: `51dcf6b` - "Add comprehensive Hyprland configuration with waybar"

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

---

## Next Steps

### Post-Installation Validation
- Compare baseline with actual installed packages using `pacman -Qe`
- Review for additional overlaps with `packages.install.arch` packages
- Validate CPU microcode package matches hardware (`intel-ucode` vs `amd-ucode`)

### Hyprland Configuration Testing
- Test configuration on actual Hyprland installation
- Validate NVIDIA-specific environment variables on target hardware
- Verify all keybindings work as expected
- Consider creating additional window rules for specific applications
- May need to adjust monitor configuration based on actual hardware

---

**Last Updated**: 2025-10-10
