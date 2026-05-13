# Omarchy v3.8.0 — Release Research

**Date researched**: 2026-05-13
**Previous version**: v3.7.1
**Commits**: 163
**Source**: GitHub release notes

---

## Summary

v3.8.0 is a large release focused on extensibility of system defaults, with new tools for setting the system-wide browser, terminal, and editor. It adds three new end-user features (reminders, live weather, video/audio/GIF transcoding) and expands hardware compatibility for Intel Panther Lake, Dell XPS haptic touchpads, Asus Zenbook, and Studio Display XDR. A new directory-style hook system (`hooks/post-update.d/`) replaces single-file hooks for easier extension management.

---

## Breaking Changes

*None*

---

## Features

- **Reminder system**: `omarchy-reminder` CLI and `Trigger > Reminder` menu (keybinds: `Super+Ctrl+R` to set, `Super+Ctrl+Alt+R` to show all, `Super+Ctrl+Shift+R` to clear all). Uses systemd timers with desktop notifications. Omarchy path: `bin/omarchy-reminder`.
- **Live weather in Waybar**: `custom/weather` module added via migration to existing Waybar configs; polls `default/waybar/weather.sh` every 60 seconds. Notification on `Super+Ctrl+Alt+W`. Omarchy path: `bin/omarchy-menu`, migration `migrations/1778139028.sh`.
- **Transcode tool**: `omarchy-transcode` and `omarchy-transcode-ascii` CLIs and `Trigger > Transcode` menu for video (mp4, gif), audio, and picture (jpg, png) transcoding. Also adds a transcode option to the right-click file manager menu. Omarchy path: `bin/omarchy-transcode`, `bin/omarchy-transcode-ascii`.
- **Setup > Defaults menus**: New `omarchy-default-browser`, `omarchy-default-editor`, `omarchy-default-terminal` CLIs and corresponding `Setup > Default > Browser/Terminal/Editor` menu entries. Omarchy path: `bin/omarchy-default-browser`, `bin/omarchy-default-editor`, `bin/omarchy-default-terminal`.
- **Install > Browser**: New `omarchy-install-browser` and `omarchy-remove-browser` scripts for installing/switching Chrome, Brave, Brave Origin, Firefox, and Zen. Omarchy path: `bin/omarchy-install-browser`, `bin/omarchy-remove-browser`.
- **Foot terminal**: Added as an installable terminal option with live theming support. Omarchy path: `bin/omarchy-install-terminal`, `bin/omarchy-theme-set-foot`.
- **Directory-style hooks**: `~/.config/omarchy/hooks/<name>.d/` directories are now supported in addition to single-file hooks. `omarchy-hook` runs all files in the `.d/` directory after the single-file hook. Omarchy path: `bin/omarchy-hook`.
- **Post-boot notification hooks**: New `post-boot` hook point added.
- **Voxtype install offer**: After first update, a post-boot notification hook prompts the user to install Voxtype dictation. Omarchy path: `install/first-run/install-voxtype.hook`.
- **Bluetooth A2DP auto-connect**: WirePlumber configured for automatic Bluetooth audio reconnection.
- **ASCII screensaver and about screen**: `omarchy-branding-screensaver` and `omarchy-branding-about` generate screensaver/about screens from any image via `omarchy-transcode-ascii`. Omarchy path: `bin/omarchy-branding-about`, `bin/omarchy-branding-screensaver`.
- **Zed editor theming**: `omarchy-install-zed` applies the current Omarchy theme on install via `omazed setup`. Omarchy path: `bin/omarchy-install-zed`.
- **SDDM theme matching**: SDDM login screen now fully matches the decryption screen style. Omarchy path: `install/login/sddm.sh`.
- **Studio Display XDR support**: Added monitor support for Apple Studio Display XDR.
- **Dell XPS 2026 haptic touchpad control**: New `Trigger > Hardware > Touchpad Haptic` menu and `dell-xps-touchpad-haptics` CLI for haptic strength control on Dell XPS 2026. Omarchy path: `bin/omarchy-hw-dell-xps-haptic-touchpad`, `bin/omarchy-haptic-touchpad` removed in favor of `bin/omarchy-hw-dell-xps-haptic-touchpad`.
- **tmux extended keys**: Enabled by default.
- **Middle-click paste consistency**: `gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true` applied at first-run to enable primary selection paste on button 3 in GTK/Chromium apps. Omarchy path: `install/first-run/gtk-primary-paste.sh`.
- **Colemak keyboard layout**: Added as an option in the ISO install flow.
- **Encryption-free ISO install**: ISO now offers an install path without encryption.
- **Notification grouping**: Identical notifications are now grouped.
- **Light/dark mode sync for pi agent**: pi coding agent now syncs with Omarchy light/dark mode.
- **Omarchy notification helper**: New `omarchy-notification-send` helper standardizes notification formatting with glyph and indented body. Omarchy path: `bin/omarchy-notification-send`.
- **File completions fallback**: `omarchy` CLI now completes with file paths after command completions are exhausted.

## Bug Fixes

- **Catppuccin theme colorscheme name**: Fixed from `catppuccin` to `catppuccin-nvim` in the Neovim Lua config. Omarchy path: `themes/catppuccin/neovim.lua`.
- **Theme refresh preserving background**: `omarchy-theme-refresh` now sets `OMARCHY_THEME_SKIP_BACKGROUND=1` before calling `omarchy-theme-set`, so refreshing no longer changes the selected background image. Omarchy path: `bin/omarchy-theme-refresh`.
- **Relative wallpaper paths**: `omarchy-theme-bg-set` now resolves paths with `realpath` before creating the background symlink, fixing broken symlinks from relative paths. Omarchy path: `bin/omarchy-theme-bg-set`.
- **No-gaps mode rounding**: No-gaps mode now also disables window rounding.
- **Helix theming legibility**: Helix editor theme contrast improved.
- **Manual screen lock display off**: `omarchy-system-lock` now powers off display 3 seconds after locking (if hyprlock is still running). Omarchy path: `bin/omarchy-system-lock`.
- **RetroArch joypad autoconfiguration**: Added `retroarch-joypad-autoconfig-git` package and set `joypad_autoconfig_dir` in RetroArch config. Omarchy path: `bin/omarchy-install-gaming-retroarch`.
- **`omarchy refresh applications` npx stubs**: Now also updates npx stubs on refresh. Omarchy path: `bin/omarchy-refresh-applications`.
- **pi package name**: Migrated to `@earendil-works/pi-coding-agent`.
- **Intel Panther Lake audio**: Added `sof-firmware` to fix audio on Intel Panther Lake systems with DSP.
- **Lenovo Yoga Pro 7 14IAH10 bass speaker**: Hardware-specific fix applied.
- **Asus Zenbook UX5406AA backlight**: Display backlight fix applied. Omarchy path: `bin/omarchy-hw-asus-zenbook-ux5406aa`.
- **Non-X-series Panther Lake hardware video acceleration**: Fixed.
- **Chromium VAAPI GL flags crash**: Migration removes `VaapiVideoDecodeLinuxGL` and `VaapiVideoEncoder` from all Chromium-based browser flag configs to prevent crashes. Omarchy path: `migrations/1778270869.sh`.
- **`omarchy` CLI metadata inconsistencies**: Fixed.
- **Installer formatting**: Fixed formatting breaking on some pre-existing Linux installations.

## Improvements

- **Idle handling (lock/sleep/wake)**: Lock flow now turns keyboard brightness and display off and back on more reliably; `omarchy-system-wake` script added. Omarchy path: `bin/omarchy-system-lock`, `bin/omarchy-system-wake`.
- **Browser theming expanded**: `omarchy-theme-set-browser` now covers Chrome and Edge in addition to Chromium and Brave, with a generalized policy-directory writer. Omarchy path: `bin/omarchy-theme-set-browser`.
- **Security setup refactored**: `omarchy-setup-fido2` and `omarchy-setup-fingerprint` split into `omarchy-setup-security-fido2`, `omarchy-remove-security-fido2`, `omarchy-setup-security-fingerprint`, and `omarchy-remove-security-fingerprint`. Omarchy path: `bin/omarchy-setup-security-fido2`, `bin/omarchy-remove-security-fido2`, etc.
- **Weather polling interval**: Reduced from 10 minutes to 1 minute; startup delayed to handle network initialization on boot.
- **Weather temperature units**: Now uses local units.
- **Hook install helper**: New `omarchy-hook-install` script for programmatic hook installation. Omarchy path: `bin/omarchy-hook-install`.
- **Brave policy directory**: Removed dedicated `/etc/brave/policies/managed` creation from `install/config/theme.sh`; policy is now managed per-browser dynamically.

## Configuration Changes

- **Waybar config (existing installs)**: Migration `migrations/1778139028.sh` adds `"custom/weather"` to `modules-center` and appends `#custom-weather` CSS to `style.css`. Omarchy path: `~/.config/waybar/config.jsonc`, `~/.config/waybar/style.css`.
- **Hook system extended**: `omarchy-hook` now also iterates `~/.config/omarchy/hooks/<name>.d/` for drop-in hook files in addition to the single-file hook. Omarchy path: `bin/omarchy-hook`.
- **OMARCHY_THEME_SKIP_BACKGROUND env var**: New variable; when set to `1`, `omarchy-theme-set` skips background image update. Used by `omarchy-theme-refresh`. Omarchy path: `bin/omarchy-theme-refresh`.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `libretro-cap32-git` | Amstrad CPC core for RetroArch |
| Added | `libretro-uae-git` | Amiga core for RetroArch |
| Added | `libretro-vice-git` | C64 core for RetroArch |
| Added | `retroarch-joypad-autoconfig-git` | RetroArch joypad autoconfiguration profiles |
| Added | `sof-firmware` | Audio firmware for Intel Panther Lake DSP |
| Added | `dell-xps-touchpad-haptics` | Dell XPS 2026 haptic touchpad control |
| Added | `omazed` | Zed editor Omarchy theme integration |
| Added | `foot` | Foot terminal emulator (installable option) |
