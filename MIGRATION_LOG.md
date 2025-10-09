# Arch Linux + Hyprland Migration Log

**Branch**: `arch-switch`
**Started**: October 2025
**Target**: Migrate from EndeavourOS + KDE Plasma to vanilla Arch Linux + Hyprland

## Migration Overview

This log documents the migration of dotfiles from an EndeavourOS-based KDE Plasma setup to a clean Arch Linux installation with Hyprland as the compositor.

## Migration History

### Phase 1: Remove Distribution Dependencies ✅
**Commit**: `bd0481c` - "Remove the dependency to endeavouros"

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
**Commit**: `90ffbad` - "Archive KDE configuration files"

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
**Date**: 2025-10-09

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

**Next Steps**:
- After system installation, compare baseline with actual installed packages using `pacman -Qe`
- Review for additional overlaps with `packages.install.arch` packages
- Validate CPU microcode package matches hardware (`intel-ucode` vs `amd-ucode`)

---

**Last Updated**: 2025-10-09
