# Omarchy v3.1.4 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.1.3
**Commits**: 54
**Source**: GitHub release notes

---

## Summary

Broad maintenance and polish release with 23 items. Majority are bug fixes covering Hyprland window rules, keybinding behavior, installer reliability, and application compatibility. Three features added: scratchpad workspace, print hotkey in image viewer, and install update confirmation prompt.

## Features

- **Scratchpad workspace hotkeys**: `Super + S` reveals scratchpad overlay; `Super + Alt + S` moves focused app to scratchpad.
- **Image viewer print hotkey**: `Ctrl + P` triggers print from within the image viewer.
- **Install update confirmation**: Confirmation prompt displayed before starting the update process.
- **omarchy-keyring package**: New package to install trusted signing keys for Omarchy.
- **Keybindings presentation reordered**: Keybindings list reorganized by order of importance.

## Bug Fixes

- Obsidian color scheme low-contrast issues corrected
- Brave browser dialogs now floating, matching Chromium rules
- New windows now appear on top in full-screen mode
- Surface keyboard compatibility fix at LUKS decryption screen
- `Alt + Shift + L` (copy URL in web app) now included in keybindings list
- Post-install USB removal message removed (no longer necessary)
- Passwords beginning with `-` no longer cause install failure
- Spurious sed error output suppressed at early installer stages
- Opening nvim via app launcher now opens nvim directly (not `$EDITOR`)
- Waybar Omarchy version-check reduced from every hour to every 6 hours
- systemd environment variables set at session startup (fixes slow app launch on some systems)
- Port 22 (SSH) no longer open by default in UFW
- cd/ls aliases now only set when eza/zoxide are present
- System time synced before Omarchy update to prevent clock-skew errors
- Android Studio dialog window rules fixed for clickability
- Ghostty default shell config updated to respect block cursor setting
- fcitx5 clipboard integration disabled to prevent hotkey conflicts

## Breaking Changes

*None*

## Configuration Changes

- **UFW default rules**: Port 22 no longer opened by default
- **Waybar Omarchy update check**: Poll interval changed from 1 hour to 6 hours
- **Ghostty shell config**: Default config sets `cursor-style = block`
- **Hyprland window rules**: New/updated rules for Brave dialogs, Android Studio dialogs, full-screen stacking
- **fcitx5 config**: Clipboard module disabled
- **systemd environment**: Variables now exported at startup

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `omarchy-keyring` | Installs trusted GPG/signing keys for Omarchy packages |

---

<details><summary>Original release notes</summary>

```
# Omarchy 3.1.4

## What changed?

* Add better presentation of keybindings in order of importance by @dhh
* Add `Super + S` to reveal scratchpad workspace overlay and `Super + Alt + S` to move an app there by @fldc
* Add `Ctrl + P` to print on the image viewer by @ctarx
* Add a confirmation before starting the update process by @ryanrhughes
* Add omarchy-keyring to install trusted signing keys by @ryanrhughes
* Add gum confirm defaults to match the active theme by @ryanrhughes
* Fix low-contrast issues in auto-generated Obsidian color schemes by @alexandersix
* Fix Brave dialogs to be floating like chromium by @Rishabh-Sarang
* Fix new windows should appear on top when in full-screen mode by @gyaaniguy
* Fix Surface keyboard compatibility with decryption screen by @brennancoslette
* Fix `Alt + Shift + L` hotkey for copying URL in a web app should be in list of keybindings by @manuel1618
* Fix post-install message to no longer include the message to remove USB key (not necessary) by @NeimadTL
* Fix install failure when passwords began with a "-" by @dakshesh14
* Fix prevent showing sed error by mistake when encountering early issues in the installer by @ryanrhughes
* Fix opening nvim via app launcher or file manager would actually open $EDITOR by @dhh
* Fix that the new-version check for Omarchy in the waybar should only run once every 6 hours not every hour by @dhh
* Fix slow application startups on some systems by setting systemd envs at startup by @ryanrhughes
* Fix port 22 should not be open by default in ufw configuration by @ctarxctarx
* Fix aliases for cd/ls should only be set if eza/zoxide is still on the system by @wiehann
* Fix time should be synced before doing an Omarchy update by @dhh
* Fix Android Studio window rules so dialogs are clickable by @AdamMusa
* Fix Ghostty default shell config to respect the block cursor by @jwkicklighter
* Fix fcitx5 clipboard interfering with hotkeys in other apps by turning it off by @cairin

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.3...v3.1.4
```

</details>
