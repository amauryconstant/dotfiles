# Omarchy v1.3.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.2.0
**Commits**: 95
**Source**: GitHub release notes

---

## Summary

v1.3.0 is a significant UX and security hardening release. The power management workflow is consolidated under `Super + Esc`, replacing a scattered set of hotkeys and a tray icon. Two clipboard and authentication security issues are addressed: Clipse is removed due to plain-text password storage, and polkit is switched to gnome-keyring-backed `polkit-gnome` to enable fingerprint sudo authentication.

## Features

- **Omarchy decryption + loading flow**: A themed decryption and loading animation/flow added during boot or unlock. Omarchy path: PR #89 by @ryanrhughes.
- **Theme-consistent power menu coloring**: The power menu now inherits the active Omarchy theme colors.
- **Fingerprint authentication for sudo**: Running `omarchy-fingerprint-setup` configures fingerprint auth for both sudo and system prompt. Requires `polkit-gnome` (see Breaking Changes).
- **Idle/sleep prevention hotkey**: `Super + Ctrl + I` toggles idle/sleep prevention.
- **Wofi menu border**: A 2px border is applied to wofi menus to visually separate them from the desktop background.
- **Impala TUI for Wi-Fi**: Wi-Fi network selection now uses the Impala TUI. Omarchy path: replaces `iwctl` interactive usage.

## Bug Fixes

- **yay-bin cleanup**: Fixed failure to clean up `yay-bin` after the yay AUR helper is installed. Fix by @bbondier.
- **Small wifi/bluetooth/volume popup windows**: Fixed undersized windows for wifi, bluetooth, and volume controls.
- **Apple-mode keyboard F-keys**: Permanently fixed F-key behavior on Apple-mode keyboards (e.g., Flow84). Fix by @reshadman.
- **User keybindings missing from `Super + K`**: Fixed that user-defined keybindings were not included in the `Super + K` keybinding reference overlay.
- **1Password 2FA broken without gnome-keyring**: Fixed 1Password failing when 2FA was configured, caused by missing `gnome-keyring` package.

## Breaking Changes

- **Power menu replaces all lock/power hotkeys**: `Super + Esc` is now the sole entry point for lock, suspend, relaunch, restart, and shutdown. All previously existing individual hotkeys for these actions are removed, as is the power icon in the top bar. `Super + Esc` is required learning to operate Omarchy. Work by @npenza.
- **polkit agent switched from hyprpolkitagent to polkit-gnome**: `hyprpolkitagent` is replaced by `polkit-gnome` to support fingerprint authentication. Systems relying on `hyprpolkitagent` behavior will need to adapt.
- **Clipse clipboard manager removed**: Clipse is removed because it stored 1Password-copied secrets in plain text. Any workflows depending on Clipse clipboard history are broken.

## Improvements

- **Wi-Fi network selection**: Replaced `iwctl` (command-line interactive) with Impala, a dedicated TUI, for a more user-friendly Wi-Fi selection experience.

## Configuration Changes

- **Power menu keybinding consolidation**: Hyprland keybinds for individual power actions removed; single `Super + Esc` binding retained for the power menu. Affects Hyprland keybinding config files.
- **Wofi border**: Wofi CSS/config updated to add a 2px border to menus.
- **polkit autostart**: Autostart entry changed from `hyprpolkitagent` to `polkit-gnome-authentication-agent-1`. Affects Hyprland autostart config.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `polkit-gnome` | Polkit authentication agent with fingerprint + gnome-keyring support |
| Added | `gnome-keyring` | Secret storage required for 1Password 2FA and polkit-gnome |
| Added | `impala` | TUI for Wi-Fi network selection |
| Removed | `hyprpolkitagent` | Replaced by polkit-gnome |
| Removed | `clipse` | Clipboard manager removed due to plain-text secret storage risk |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add a beautiful Omarchy decryption + loading flow by @ryanrhughes in #89
* Add theme-consistent coloring of the new power menu by @dhh
* Add fingerprint authentication to sudo + system prompt when using `omarchy-fingerprint-setup` by @dhh in #109
* Add idle/sleep prevention on `Super + Ctrl + I` by @dhh
* Add a 2px border to the wofi menus to better set them apart from the background by @dhh
* Switch to using power menu exclusively using `Super + Esc` to control lock/suspend/relaunch/restart/shutdown. Remove the confusingly prolific hotkeys + power icon in the top right. `Super + Esc` is now required learning to operate Omarchy. Work by @npenza.
* Switch from iwctl to Impala TUI for selecting Wi-Fi networks by @da-maltsev
* Switch from hyprpolkitagent to polkit-gnome to better support fingerprint authentication by @dhh
* Remove Clipse as a clipboard manager as it would store passwords from 1password in plain text by @dhh
* Fix cleaning up yay-bin after installing it by @bbondier
* Fix that wifi/bluetooth/volume windows were too small by @dhh
* Fix F keys on Apple-mode keyboards like the Flow84 permantly by @reshadman
* Fix user keybindings weren't being included in `Super + K` by @dhh
* Fix that 1password wouldn't work with 2FA setup because `gnome-keyring` was missing by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.2.0...v1.3.0
```

</details>
