# Omarchy v3.7.0 — Release Research

**Date researched**: 2026-05-13
**Previous version**: v3.6.0
**Commits**: 227
**Source**: GitHub release notes

---

## Summary

v3.7.0 is "The Gaming Edition", adding a full suite of gaming installers (Steam, RetroArch, Lutris, Heroic, Moonlight, Xbox Cloud Gaming, Xbox controller support) alongside a unified `omarchy` CLI that consolidates and renames many `omarchy-*` scripts. The release also expands aesthetics across all themes with unified Plymouth/SDDM unlock screen theming and Omarchy logo backgrounds, and adds OCR text extraction, monitor mirroring, and numerous hardware compatibility fixes for ASUS Panther Lake systems.

---

## Breaking Changes

- **Command renames (omarchy CLI unification)**: Nine `omarchy-*` scripts were renamed as part of the new `omarchy` CLI namespace. Personal scripts, hotkey bindings, or Waybar/Hypr configs referencing old names must be updated. Omarchy-shipped configs are migrated automatically. See table in "Configuration Changes" section.

---

## Features

- **Unified `omarchy` CLI**: New `bin/omarchy` script (1028 lines) acts as a top-level dispatcher for all `omarchy-*` subcommands, with group descriptions, metadata scanning, routing, and alias support. Omarchy path: `bin/omarchy`.
- **OCR text extraction**: `bin/omarchy-capture-text-extraction` uses `hyprpicker` to freeze the screen, `slurp` for region selection, `grim` to capture, and `tesseract` to extract text, copying the result to clipboard. Bound to `Super + Ctrl + PrtScr`. Omarchy path: `bin/omarchy-capture-text-extraction`.
- **Monitor mirroring**: `bin/omarchy-hyprland-monitor-internal-mirror` adds on/off/toggle/recover mirroring of the internal laptop display to a connected external display. Bound to `Super + Ctrl + Alt + Del`. Omarchy path: `bin/omarchy-hyprland-monitor-internal-mirror`.
- **cliamp TUI music player**: Added `cliamp` to `install/omarchy-base.packages` as a default package, launched via `Super + Shift + Alt + M`.
- **ghui GitHub TUI**: Lazy-installed GitHub TUI (`ghui`) added under `Install > Dev`.
- **New shell aliases**: `ic='tdl c'`, `ix='tdl cx'`, `icx='tdl c cx'` added to `default/bash/aliases`. The previous `i='tdl c cx'` alias was replaced.
- **dosfstools default package**: `dosfstools` (provides `fsck.fat` and `mkfs.fat`) added to `install/omarchy-base.packages`.
- **`transcode-video-gif` function**: New function for converting video files to GIFs.
- **ASUS ExpertBook Panther Lake support**: `bin/omarchy-hw-asus-expertbook-b9406` detects the B9406 series via model string match and Intel PTL detection. Dedicated scripts `install/config/hardware/asus/fix-asus-ptl-b9406-display.sh` and `fix-asus-ptl-b9406-touchpad.sh` added for display and touchpad compatibility. Fingerprint reader support also included.
- **`fred=on` kernel parameter**: Intel Panther Lake systems receive a kernel optimization via the PTL kernel config path.
- **Two-finger tap right-click**: Enabled by default on new system setups for touchpads.
- **Push-to-talk keybind for Voxtype**: `F5` bound for Voxtype push-to-talk.

## Gaming

- **Streamlined Steam installer**: `bin/omarchy-install-gaming-steam` installs Steam and lib32 GPU drivers automatically (no user input), then launches Steam immediately. Omarchy path: `bin/omarchy-install-gaming-steam`.
- **Preconfigured RetroArch**: `bin/omarchy-install-gaming-retroarch` installs `retroarch` and a full `libretro-*` core set from official Arch repos (no longer AUR-dependent), plus `libretro-fbneo-git` and `libretro-database-git`. Creates `~/Games/bios` and `~/Games/roms`. Omarchy path: `bin/omarchy-install-gaming-retroarch`.
- **Xbox controller Bluetooth support**: `bin/omarchy-install-gaming-xbox-controllers` installs `xpadneo-dkms`, blacklists the conflicting `xpad` driver, and hot-swaps modules so a reboot is typically not needed. Omarchy path: `bin/omarchy-install-gaming-xbox-controllers`.
- **Lutris Launcher**: `bin/omarchy-install-gaming-lutris` added under `Install > Gaming` for running Battle.net games.
- **Heroic Launcher**: `bin/omarchy-install-gaming-heroic` added for Epic Games store access.
- **Moonlight GameStream client**: `bin/omarchy-install-gaming-moonlight` added for remote PC game streaming from Sunshine server.
- **Xbox Cloud Gaming web app**: `bin/omarchy-install-gaming-xbox-cloud` added for Xbox Game Pass cloud play.
- **Gaming remove scripts**: `bin/omarchy-remove-gaming-*` scripts added for Steam, RetroArch, Lutris, Heroic, Moonlight, Xbox Cloud, Xbox Controllers, GeFORCE Now, and Minecraft.

## Bug Fixes

- **`SDL_VIDEODRIVER` env blocking Steam games**: Obstructive env var removed. Omarchy path: related to Steam game launch config.
- **Scrambled screen recording frames**: Capture pipeline guarded; only re-encodes when garbage frames are detected.
- **Mid-transition screenshots**: `hyprpicker` kept alive until `grim` capture completes.
- **Screen recording with webcam**: Switched to screenshot-style region/screen selection.
- **Chrome dark mode**: Proper configuration applied instead of workaround.
- **ASUS ROG Flow Z13 cursor jumping**: Disabled-while-typing fixed for detachable keyboard. Omarchy path: `bin/omarchy-hw-asus-rog`.
- **Kernel update check resilience**: "Your kernel has been updated" check made more robust.
- **`lstopo.desktop` hidden**: Entry hidden from app launcher via `applications/hidden/lstopo.desktop`.
- **ISO installer target selection**: Prevents selecting the install media as the install target. Omarchy path: ISO installer scripts.
- **npx wrapper PATH isolation**: Fixed runtime so it is isolated from project PATH.
- **UFW Docker DNS for 192.168 networks**: Added `ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53` to `install/first-run/firewall.sh`.
- **Background selector symlink support**: `bin/omarchy-theme-bg-set` now recognizes symlinks.
- **Walker not restarting after web app removal**: Restarts Walker after web app removal so entries disappear immediately.
- **VSCode everforest theme**: Deprecated theme reference fixed. Omarchy path: `themes/everforest/vscode.json`.
- **Internal monitor disable for non-eDP-1 systems**: `bin/omarchy-hyprland-monitor-internal` fixed to detect built-in display name dynamically rather than assuming `eDP-1`.
- **`refresh-config` missing target directory**: Fixed crash when target directory does not exist.
- **"Bistream" typo**: Corrected to "Bitstream".
- **Automatic power profile on boot**: Fixed for USB-C only charging machines.
- **Custom DNS IPv6 servers**: `bin/omarchy-setup-dns` now also provides IPv6 DNS servers.
- **Low ulimit ceiling**: System ulimit raised.
- **Hybrid GPU toggle visibility**: `bin/omarchy-hw-hybrid-gpu` now only shows toggle when hybrid GPU is actually detected.
- **Dell XPS PTL kernel scope**: `install/config/hardware/intel/ptl-kernel.sh` now only installs `linux-ptl` on Dell XPS Panther Lake; other PTL systems use vanilla kernel 7.0.3.

## Improvements

- **Boot time**: Delays in boot sequence reduced by 5-8 seconds.
- **Limine rebuild**: Install sequence now rebuilds Limine once instead of four times.
- **Plymouth boot unlock theming**: `bin/omarchy-plymouth-set`, `bin/omarchy-plymouth-set-by-theme`, `bin/omarchy-plymouth-preview`, and `bin/omarchy-plymouth-reset` added; accessible via `Style > Unlock` menu and `omarchy plymouth`.
- **SDDM login screen theme sync**: SDDM theme now matches the active Plymouth unlock theme for visual consistency.
- **Omarchy logo backgrounds**: New `omarchy.png` background added to every default theme directory.
- **Text contrast improvements**: `colors.toml` updated for Flexoki Light, Vantablack, Ethereal, Hackerman, and White themes.
- **Tokyo Night new backgrounds**: Two new OMA logo-based backgrounds added (`backgrounds/4-oma-cityscape.jpg`, `backgrounds/5-oma.jpg`).
- **Older theme compatibility**: `bin/omarchy-theme-colors-from-alacritty` extracts `colors.toml` from `alacritty.toml` palette for themes that predate the colors.toml format; runs on install and skips if `colors.toml` already exists.
- **Helix editor theming**: `bin/omarchy-install-helix` symlinks `~/.config/omarchy/current/theme/helix.toml` into Helix's themes directory and seeds a `config.toml` pointing to the `omarchy` theme.
- **gum theming**: Theme support added for the `gum` TUI toolkit.
- **Brave Origin browser theming**: `bin/omarchy-theme-set-browser` updated for Brave Origin.
- **Color highlighting in man pages**: Color paging added for `man`.
- **Omarchy menu selection highlight**: Subtle highlight added to selected items in Omarchy menus.
- **Limine progress bar smoothness**: More animation steps added to Limine progress bar.
- **Theme install over SSH**: `bin/omarchy-theme-bg-install` now supports SSH in addition to web installs.
- **Direct Boot toggle**: `bin/omarchy-config-direct-boot` (`Super + Ctrl + O`) skips the Limine rollback screen and goes directly to boot unlock.
- **Passwordless sudo toggle**: New `bin/omarchy-sudo-passwordless` (renamed from `omarchy-sudo-passwordless-toggle`) accessible via `Trigger > Toggle > Passwordless Sudo`.
- **Touchscreen toggle**: `bin/omarchy-hw-touchscreen` added to `Trigger > Hardware` for enabling/disabling touchscreen recognition.
- **Touchpad toggle**: `bin/omarchy-hw-touchpad` added to `Trigger > Hardware` for enabling/disabling the touchpad.
- **Apple display brightness**: Normal brightness hotkeys now control Apple external display brightness via `bin/omarchy-hyprland-monitor-focused-apple`.
- **Max/min brightness shortcuts**: `Shift + Brightness Up` sets maximum brightness; `Shift + Brightness Down` sets minimum. `bin/omarchy-brightness-keyboard-mute` added.
- **Brightness adjustment steps**: Consistent steps with slow ramp below 5%. Omarchy path: `bin/omarchy-brightness-display`, `bin/omarchy-brightness-display-apple`.
- **Waybar battery right-click**: Right-clicking the battery icon shows a detailed battery notification.
- **Persistent monitor scaling**: `Super + /` scaling persists in `monitors.conf` when only a single monitor is declared.
- **Unified mic mute LED handling**: `bin/omarchy-audio-input-mute` handles hardware mic-mute LED syncing for all laptops internally, replacing the separate XPS and ThinkPad variants.

## Configuration Changes

- **`omarchy-*` command renames**: Scripts renamed as part of the unified `omarchy` CLI. Personal configs referencing old names must be updated manually.

| Old name | New name |
|----------|----------|
| `omarchy-cmd-audio-switch` | `omarchy-audio-output-switch` |
| `omarchy-cmd-mic-mute` | `omarchy-audio-input-mute` |
| `omarchy-cmd-screenrecord` | `omarchy-capture-screenrecording` |
| `omarchy-cmd-screenshot` | `omarchy-capture-screenshot` |
| `omarchy-cmd-first-run` | `omarchy-first-run` |
| `omarchy-cmd-screensaver` | `omarchy-screensaver` |
| `omarchy-cmd-share` | `omarchy-menu-share` |
| `omarchy-lock-screen` | `omarchy-system-lock` |
| `omarchy-sudo-passwordless-toggle` | `omarchy-sudo-passwordless` |

- **Mic mute variants removed**: `omarchy-cmd-mic-mute-xps` and `omarchy-cmd-mic-mute-thinkpad` are deleted; hardware LED handling is now inside `omarchy-audio-input-mute`. Omarchy path: `bin/omarchy-audio-input-mute`.
- **`i` alias replaced**: `default/bash/aliases` — old `i='tdl c cx'` removed; replaced by `ic`, `ix`, and `icx` aliases.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `cliamp` | TUI music player (default install) |
| Added | `dosfstools` | FAT filesystem tools (`fsck.fat`, `mkfs.fat`) for /boot repair |
| Added | `tesseract` | OCR engine for screen text extraction |
| Added | `tesseract-data-eng` | English language data for tesseract |
| Removed | `dart` | Removed from `omarchy-other.packages` |
| Removed | `htop` | Removed from `omarchy-other.packages` |
| Removed | `intltool` | Removed from `omarchy-other.packages` |
| Removed | `iwd` | Removed from `omarchy-other.packages` |
| Removed | `libsass` | Removed from `omarchy-other.packages` |
| Removed | `sassc` | Removed from `omarchy-other.packages` |
| Removed | `wget` | Removed from `omarchy-other.packages` |
