# Omarchy v3.2.0 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.1.7
**Commits**: 160
**Source**: GitHub release notes

---

## Summary

Major feature release (160 commits). Ghostty becomes the new default terminal, JetBrainsMono Nerd Font becomes the new default font, two new themes (Ethereal, Hackerman), visual theme picker, BlueTUI replaces GTK Bluetooth UI, and a new stable Arch mirror to lag edge by one month. 32 bug fixes covering screensaver, screen recording, window management, and walker stability.

## Features

- **Ghostty as default terminal**: New default for fresh installs (existing users: `Install > Terminal`). Includes Ghostty-specific scrolling tweak and font defaults.
- **JetBrainsMono Nerd Font as default font**: Caskaydia renders poorly in Ghostty. Existing users: `Style > Font`.
- **New stable Arch mirror + stable package repo**: Lags edge by one month, snapshots on the 1st of each month, rolls out last Monday at 10am UTC. Pioneers can opt-in to edge via `omarchy-refresh-pacman-mirrorlist edge`.
- **New themes**: Ethereal and Hackerman by @bjarneo.
- **Visual theme picker**: Theme picker now shows visual previews. Extra themes can add `preview.png` (16:9) to participate.
- **BlueTUI**: Replaces GTK Bluetooth configuration with a TUI that matches the wifi TUI aesthetic.
- **`try` command**: @tobi's experiment namespacing tool, organizes quick code attempts under `~/Work/tries`.
- **Font on lock screen**: Lock screen now reflects active font; fingerprint prompt only shown when sensor is active.
- **New keybindings**: `Super + Alt + ,` (open last notification), `Super + Alt + Arrows` (move between tiling group tabs), `Super + Shift + Alt + Left/Right` (move workspaces between monitors), `Super + Ctrl + Shift + Alt + Arrows` (resize Ghostty splits by 100 lines), AAC audio codec for screen recordings.
- **Xbox controller setup**: `Install > Gaming > Xbox controller` by @ericjim.
- **`omarchy-hyprland-window-pop` size/position parameters**: Optional parameters for custom window pop positioning.
- **`usage` package**: Added as default to enable mise tab completion.

## Bug Fixes

- Application launcher no longer limited to first 50 entries
- Screensaver works with all three default terminals (Ghostty, Kitty, Alacritty)
- Ability to decline an Omarchy update restored
- PS1 setting removed (redundant with Starship)
- DaVinci Resolve dialog window management
- Microsoft Edge class name match in window rules
- Windows scaling now based on focused monitor (not first)
- TUI installer uses xdg-terminal-exec
- Helium browser match in omarchy-launch-webapp
- Tiling group window number switching on non-US keyboard layouts
- Low contrast in Matte Black sway OSD overlays
- Screen wakes on both mouse move and keyboard
- Wifi settings launch-or-focus instead of opening multiple instances
- Missing tab completion for mise (added `usage` package)
- Overly fast Ghostty terminal scrolling on mouse wheel
- walker/elephant now run via systemd instead of exec-once
- Terminal cwd only kicks in when active window is a shell
- Consistent `org.omarchy.*` app-ids for all TUIs
- `format-disk` now uses exFAT instead of ext4 for Windows/macOS compatibility
- JetBrains mouse focus issues
- Workspace 10 was previously omitted from workspace rules
- imv, mpv, and 1password now float instead of tile by default
- Everforest color scheme in Ghostty/Kitty uses lighter variant (matching Alacritty)
- Waybar tray icon more intuitive
- Bluetooth icon reflects connected state when any device is connected
- Walker config updated for breaking changes in latest Walker version
- Screensaver cursor no longer blinks in Ghostty (upgraded to TTE 13)
- Hitting screenrecording hotkey during recording now stops the recording
- Screen recording on external GPUs and with HDR via desktop-portal-capture
- Screen recording CPU fallback for systems without GPUs

## Breaking Changes

*None*

## Configuration Changes

- **Default terminal**: Ghostty (was Alacritty). Config path: `~/.config/ghostty/`
- **Default font**: JetBrainsMono Nerd Font (was Caskaydia Mono Nerd Font Propo)
- **`format-disk` filesystem**: exFAT instead of ext4
- **Walker config**: Updated for latest Walker breaking changes
- **TUI app-ids**: Now use `org.omarchy.*` namespace consistently
- **Package mirror**: New stable mirror as default (edge available via `omarchy-refresh-pacman-mirrorlist edge`)

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added (default) | `ghostty` | New default terminal |
| Added (default) | `ttf-jetbrains-mono-nerd` | New default font |
| Added | `bluetui` | TUI Bluetooth manager |
| Added | `try` | Experiment namespacing tool |
| Added | `usage` | Enables mise tab completion |
| Upgraded | `tte` → v13 | Fixes blinking cursor in screensaver |
| Added | Xbox controller tools | Via `Install > Gaming` |

---

<details><summary>Original release notes</summary>

```
# What changed?

## New keys and capabilities

* Add new stable Arch mirror + stable pkg repository that will lag the edge by a month by @dhh + @ryanrhughes
* Add Ghostty as the new default terminal (existing users can switch using Install > Terminal) by @dhh
* Add JetBrainsMono Nerd Font as the new default font by @dhh
* Add Ethereal and Hackerman as new theme options by @bjarneo
* Add visual theme picker by @tahayvr
* Add BlueTUI instead of GTK bluetooth configuration by @a-sologub + @dhh
* Add @tobi's excellent try command by @dhh
* Add font changing to the lock screen and only show fingerprint when fingerprint sensor is active by @mlombardi96
* Add `Super + Alt + Comma` to invoke/open the last notification by @czroth
* Add `Super + Alt + Arrows` to move between tiling group tabs by @chrislewis
* Add `Super + Shift + Alt + Arrow Left/Right` to move workspaces between monitors by @jheuing
* Add `Super + Ctrl + Shift + Alt + Arrows` to move splits in Ghostty by 100 lines (instead of default 10) by @dhh
* Add AAC audio codec for screen recordings for better compatibility by @robzolkos
* Add Xbox controller setup installer under Install > Gaming by @ericjim
* Add optional size + positioning parameters to `omarchy-hyprland-window-pop` command by @DarrenVictoriano

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.7...v3.2.0
```

</details>
