# Hyprland Keybindings Reference

**Dynamic help**: Press `SUPER+/` to view all keybindings with search — always accurate, queries
`hyprctl` directly. This file is a static overview and can drift; the viewer cannot.

## Quick Reference

### Applications (`applications.conf.tmpl`)

| Keys | Action |
|------|--------|
| `SUPER+Return` | Terminal in current directory |
| `SUPER+D` | Application launcher (Wofi drun) |
| `SUPER+E` | File manager (Thunar, launch-or-focus) |
| `SUPER+W` | Web browser (Firefox) |
| `SUPER+O` | Neovim session picker (Ghostty + Zellij) |
| `SUPER+SHIFT+O` | Neovim workspace picker (Ghostty-native, no Zellij) |
| `SUPER+C` | Clipboard history |
| `SUPER+SHIFT+C` | Delete from clipboard history |

### Window management (`window-management.conf`)

| Keys | Action |
|------|--------|
| `SUPER+Q` | Close window |
| `SUPER+V` | Toggle floating |
| `SUPER+F` | Toggle fullscreen |
| `SUPER+S` | Toggle scratchpad (special workspace `magic`) |
| `SUPER+SHIFT+S` | Move to scratchpad |
| `SUPER+SHIFT+P` | Picture-in-picture (float + resize + pin) |

### Focus and resize (`focus-navigation.conf`, `window-resizing.conf`)

| Keys | Action |
|------|--------|
| `SUPER+Arrows` / `SUPER+H/J/K/L` | Move focus |
| `SUPER+SHIFT+Arrows` | Move window within workspace |
| `SUPER+CTRL+H/L` | Cycle previous/next in group (tabbed) |
| `SUPER+CTRL+Arrows` | Resize active window |
| `SUPER+LMB` / `SUPER+RMB` | Mouse move / resize (`bindm`) |

### Workspaces and monitors (`workspace-management.conf`)

Per-monitor independent workspaces 1–10 via hyprsplit (`split:*` dispatchers).

| Keys | Action |
|------|--------|
| `SUPER+1..9,0` | Switch to workspace 1–10 (current monitor) |
| `SUPER+SHIFT+1..9,0` | Move window to workspace (silent, stay put) |
| `SUPER+Tab` / `SUPER+SHIFT+Tab` | Next / previous workspace |
| `SUPER+Wheel` | Next / previous workspace |
| `SUPER+ALT+Tab` | Empty workspace |
| `SUPER+ALT+Arrows` | Focus monitor (left/right/up/down) |
| `SUPER+ALT+S` | Swap workspaces between monitors |
| `SUPER+ALT+M` | Move to other monitor |
| `SUPER+ALT+G` | Grab rogue windows |
| `SUPER+SHIFT+ALT+Left/Right` | Move whole workspace to left/right monitor |

> ⚠️ `SUPER+ALT+M` is **double-bound** — also "Toggle meeting transcription" in `voice.conf.tmpl`.
> Present identically in the `.lua` twins, so it is a real conflict, not `.conf`/`.lua` drift.
> Tracked in `_plans/OMARCHY.md`.

### System control (`system-control.conf`)

| Keys | Action |
|------|--------|
| `SUPER+L` | Lock screen |
| `SUPER+Space` | Main system menu |
| `SUPER+/` | Keybinding help (interactive viewer) |
| `SUPER+SHIFT+Q` | Power menu (wlogout) |
| `SUPER+SHIFT+N` | Notification center (swaync) |

### Desktop utilities (`desktop-utilities.conf`)

| Keys | Action |
|------|--------|
| `SUPER+A` / `SUPER+SHIFT+A` | Audio output switcher / pavucontrol |
| `SUPER+B` | Toggle Waybar |
| `SUPER+G` | Toggle gaps (presentation mode) |
| `SUPER+I` / `SUPER+SHIFT+I` | Toggle idle lock / idle no-lock (display still sleeps) |
| `SUPER+M` | Monitor switcher |
| `SUPER+N` | Nightlight toggle |
| `SUPER+U` | Utilities menu |
| `SUPER+CTRL+B` / `SUPER+CTRL+W` | Bluetooth manager / WiFi (nmtui) |
| `SUPER+CTRL+Y` | Activity monitor (btop) |
| `SUPER+CTRL+Z` / `SUPER+CTRL+ALT+Z` | Cursor zoom in / out |
| `SUPER+CTRL+ALT+B` | Battery status |

### Theme and session (`theme-session.conf`)

| Keys | Action |
|------|--------|
| `SUPER+SHIFT+Y` | Toggle dark mode (darkman) |
| `SUPER+SHIFT+CTRL+Space` | Theme menu |

### Voice dictation (`voice.conf.tmpl`)

Recording switches to the `voxtype_recording` submap (`../../conf.d/voxtype-submap.conf`) so
modifiers can't interfere. Parakeet bindings are **desktop-only** — gated
`{{ if ne .chassisType "laptop" }}` because the laptop is Cohere-only (RAM).

| Keys | Action |
|------|--------|
| `SUPER+T` | Cohere push-to-talk (default, multilingual) |
| `SUPER+ALT+T` | Parakeet streaming toggle *(desktop)* |
| `SUPER+CTRL+T` | Parakeet push-to-talk *(desktop)* |
| `SUPER+ALT+M` | Meeting transcription toggle — see conflict note above |

### Media keys (`media-keys.conf`)

Flags: `l` = works while locked (hyprlock), `e` = repeats on hold.

| Keys | Bind type | Action |
|------|-----------|--------|
| `XF86AudioRaiseVolume` / `LowerVolume` / `Mute` | `bindeld` | Volume via pamixer |
| `XF86MonBrightnessUp` / `Down` | `bindeld` | Brightness via brightnessctl |
| `XF86AudioPlay` / `Pause` / `Next` / `Prev` | `bindld` | Playback via playerctl (MPRIS) |

### Screenshots (`screenshots.conf`)

| Keys | Action |
|------|--------|
| `Print` | Smart screenshot (Satty editor) |
| `SHIFT+Print` | Quick screenshot to clipboard |
| `SUPER+Print` | Color picker (hyprpicker) |
| `SUPER+SHIFT+Print` | Fullscreen screenshot |
| `ALT+SHIFT+Print` | Screen recording with audio (toggle) |
| `CTRL+ALT+SHIFT+Print` | Fullscreen recording with audio (toggle) |

## Modifier Hierarchy

| Modifier | Purpose |
|----------|---------|
| `SUPER` | Primary action — launch, focus, switch, toggle |
| `SUPER+SHIFT` | Move / variant of the SUPER action |
| `SUPER+CTRL` | Resize, system/hardware utilities |
| `SUPER+ALT` | Monitor-level and cross-monitor workspace operations |

## File Organization

Each file below has a parallel `.lua` twin (inactive until the Lua entry point is unblocked — see
`_guides/HYPRLAND_LUA_CUTOVER.md`). Files are sourced by `hyprland.conf` in alphabetical order.

| File | Scope |
|------|-------|
| `applications.conf.tmpl` | App launchers |
| `desktop-utilities.conf` | Audio, gaps, Waybar, nightlight, idle, zoom |
| `focus-navigation.conf` | Focus + move within workspace |
| `media-keys.conf` | Volume, brightness, playback |
| `screenshots.conf` | Screenshots and recording |
| `system-control.conf` | Lock, power, menus, help |
| `theme-session.conf` | Theme switching, dark mode |
| `voice.conf.tmpl` | Voxtype dictation (chassis-gated) |
| `window-management.conf` | Close, float, fullscreen, scratchpad |
| `window-resizing.conf` | Resize + mouse binds |
| `workspace-management.conf` | Workspaces + monitors (hyprsplit) |

Bindings use `bindd`: `bindd = MODS, KEY, description, dispatcher, args`. The description is the
**third** field, before the dispatcher, and is what `SUPER+/` displays. Always supply one.

## Complete Reference

**Press `SUPER+/`** — interactive viewer, searchable, sourced live from Hyprland.
