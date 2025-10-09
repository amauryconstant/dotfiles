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

---

**Last Updated**: 2025-10-09
