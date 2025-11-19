# Themes - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/themes/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Table of Contents

1. Quick Reference
2. Theme System Architecture
3. Semantic Variable Schema
4. Theme-to-Semantic Mappings
5. Application Integration
6. Theme Switching Methods
7. Theme Style Guides Summary
8. Asset Organization (Wallpapers, Icons, Cursors, Fonts)

---

## Quick Reference

- **Theme system**: Semantic variable abstraction (16 variables)
- **8 variants**: Catppuccin (latte/mocha), Rose Pine (dawn/moon), Gruvbox (light/dark), Solarized (light/dark)
- **Switching**: `theme switch <name>`, darkman (solar), Super+Shift+Y (toggle), Super+Shift+Ctrl+Space (menu)
- **Location**: `~/.config/themes/current` → symlink to active theme
- **Apps using system**: Waybar, Dunst, Wofi, Wlogout, Hyprland borders, Ghostty (palette), Hyprlock

---

## Theme System Architecture

### Symlink-Based Switching

```
~/.config/themes/
├── current → catppuccin-mocha/    # Symlink to active theme
├── catppuccin-latte/
├── catppuccin-mocha/
├── gruvbox-dark/
├── gruvbox-light/
├── rose-pine-dawn/
├── rose-pine-moon/
├── solarized-dark/
└── solarized-light/
```

### Per-Theme Files

Each theme directory contains:
```
catppuccin-mocha/
├── dunst.conf           # Direct hex values (INI format)
├── ghostty.conf         # Terminal palette (ANSI 0-15)
├── hyprland.conf        # Hyprland variables ($activeBorder, $inactiveBorder)
├── hyprlock.conf        # Lock screen colors (TODO: not yet connected)
├── waybar.css           # Semantic variable definitions
├── wlogout.css          # Button colors
└── wofi.css             # Launcher styling
```


### Application Integration

Applications import theme-specific configs:

**Waybar** (`style.css.tmpl`):
```css
@import "../themes/current/waybar.css";  /* Loads semantic variables */
```

**Dunst** (`dunstrc.tmpl`):
```ini
!include ~/.config/themes/current/dunst.conf
```

**Hyprland** (`hyprland.conf`):
```
source = ~/.config/themes/current/hyprland.conf
```

**Ghostty** (`config`):
```
theme = current
```

---

## Semantic Variable Schema

**16 variables** organized into 3 categories:

### Background Hierarchy (4)

| Variable | Role | Usage |
|----------|------|-------|
| `@bg-primary` | Main background | Bars, windows, primary canvas |
| `@bg-secondary` | Elevated surfaces | Hover states, cards, inputs |
| `@bg-tertiary` | Popovers | Notifications, tertiary elevation |
| `@bg-overlay` | Modal overlays | Dialogs, semi-transparent |

### Foreground/Text Hierarchy (4)

| Variable | Role | Usage |
|----------|------|-------|
| `@fg-primary` | Primary text | Body content, main labels |
| `@fg-secondary` | Secondary text | Subtitles, window title |
| `@fg-muted` | Disabled/inactive | Unfocused, low contrast |
| `@fg-contrast` | High contrast | Text on colored backgrounds |

### Accent Colors (8 semantic roles)

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-primary` | Active states | Clock, active workspace, battery plugged |
| `@accent-info` | Connectivity | Network, Bluetooth, battery charging |
| `@accent-success` | Success states | Battery normal, positive indicators |
| `@accent-warning` | Warnings | Battery low (~20%), backlight, caution |
| `@accent-error` | Errors/urgent | Battery critical (<10%), urgent workspace |
| `@accent-highlight` | Secondary actions | Audio/PulseAudio, special states |
| `@accent-secondary` | Tertiary actions | Alternative interactive elements |
| `@accent-tertiary` | Quaternary | Lock, logout buttons |

---

## Theme-to-Semantic Mappings

### Catppuccin Mocha (Dark)

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#1e1e2e` | base | `@fg-primary` | `#cdd6f4` | text |
| `@bg-secondary` | `#313244` | surface0 | `@fg-secondary` | `#bac2de` | subtext1 |
| `@bg-tertiary` | `#45475a` | surface1 | `@fg-muted` | `#9399b2` | overlay2 |
| `@bg-overlay` | `#181825` | mantle | `@fg-contrast` | `#11111b` | crust |

**Accents**: blue (#89b4fa), teal (#94e2d5), green (#a6e3a1), yellow (#f9e2af), red (#f38ba8), mauve (#cba6f7), sapphire (#74c7ec), peach (#fab387)

### Catppuccin Latte (Light)

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#eff1f5` | base | `@fg-primary` | `#4c4f69` | text |
| `@bg-secondary` | `#ccd0da` | surface0 | `@fg-secondary` | `#5c5f77` | subtext1 |
| `@bg-tertiary` | `#bcc0cc` | surface1 | `@fg-muted` | `#7c7f93` | overlay2 |
| `@bg-overlay` | `#e6e9ef` | mantle | `@fg-contrast` | `#dce0e8` | crust |

**Accents**: blue (#1e66f5), teal (#179299), green (#40a02b), yellow (#df8e1d), red (#d20f39), mauve (#8839ef), sapphire (#209fb5), peach (#fe640b)

### Rose Pine Moon (Dark)

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#232136` | base | `@fg-primary` | `#e0def4` | text |
| `@bg-secondary` | `#2a273f` | surface | `@fg-secondary` | `#908caa` | subtle |
| `@bg-tertiary` | `#393552` | overlay | `@fg-muted` | `#6e6a86` | muted |
| `@bg-overlay` | `#393552` | overlay | `@fg-contrast` | `#232136` | base |

**Accents**: pine (#3e8fb0), foam (#9ccfd8), foam (#9ccfd8), gold (#f6c177), love (#eb6f92), iris (#c4a7e7), foam (#9ccfd8), rose (#ea9a97)

### Rose Pine Dawn (Light)

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#faf4ed` | base | `@fg-primary` | `#575279` | text |
| `@bg-secondary` | `#fffaf3` | surface | `@fg-secondary` | `#797593` | subtle |
| `@bg-tertiary` | `#f2e9e1` | overlay | `@fg-muted` | `#9893a5` | muted |
| `@bg-overlay` | `#f2e9e1` | overlay | `@fg-contrast` | `#faf4ed` | base |

**Accents**: pine (#286983), foam (#56949f), foam (#56949f), gold (#ea9d34), love (#b4637a), iris (#907aa9), foam (#56949f), rose (#d7827e)

### Gruvbox Dark

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#282828` | dark0 | `@fg-primary` | `#ebdbb2` | light1 |
| `@bg-secondary` | `#3c3836` | dark1 | `@fg-secondary` | `#d5c4a1` | light2 |
| `@bg-tertiary` | `#504945` | dark2 | `@fg-muted` | `#a89984` | light4 |
| `@bg-overlay` | `#3c3836` | dark1 | `@fg-contrast` | `#fbf1c7` | light0 |

**Accents**: bright_blue (#83a598), bright_aqua (#8ec07c), bright_green (#b8bb26), bright_yellow (#fabd2f), bright_red (#fb4934), bright_purple (#d3869b), bright_aqua (#8ec07c), bright_orange (#fe8019)

### Gruvbox Light

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#fbf1c7` | light0 | `@fg-primary` | `#3c3836` | dark1 |
| `@bg-secondary` | `#ebdbb2` | light1 | `@fg-secondary` | `#504945` | dark2 |
| `@bg-tertiary` | `#d5c4a1` | light2 | `@fg-muted` | `#7c6f64` | dark4 |
| `@bg-overlay` | `#ebdbb2` | light1 | `@fg-contrast` | `#282828` | dark0 |

**Accents**: neutral_blue (#458588), neutral_aqua (#689d6a), neutral_green (#98971a), neutral_yellow (#d79921), neutral_red (#cc241d), neutral_purple (#b16286), neutral_aqua (#689d6a), neutral_orange (#d65d0e)

### Solarized Dark

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#002b36` | base03 | `@fg-primary` | `#839496` | base0 |
| `@bg-secondary` | `#073642` | base02 | `@fg-secondary` | `#93a1a1` | base1 |
| `@bg-tertiary` | `#586e75` | base01 | `@fg-muted` | `#586e75` | base01 |
| `@bg-overlay` | `#073642` | base02 | `@fg-contrast` | `#fdf6e3` | base3 |

**Accents**: blue (#268bd2), cyan (#2aa198), green (#859900), yellow (#b58900), red (#dc322f), violet (#6c71c4), cyan (#2aa198), orange (#cb4b16)

### Solarized Light

| Semantic | Hex | Native Name | Semantic | Hex | Native Name |
|----------|-----|-------------|----------|-----|-------------|
| `@bg-primary` | `#fdf6e3` | base3 | `@fg-primary` | `#657b83` | base00 |
| `@bg-secondary` | `#eee8d5` | base2 | `@fg-secondary` | `#586e75` | base01 |
| `@bg-tertiary` | `#93a1a1` | base1 | `@fg-muted` | `#93a1a1` | base1 |
| `@bg-overlay` | `#eee8d5` | base2 | `@fg-contrast` | `#002b36` | base03 |

**Accents**: Same as dark (symmetric design)

---

## Application Integration

### Waybar (`waybar/style.css.tmpl`)

**Format**: GTK CSS with `@variable` references
**Variables used**: All 16 semantic variables

**Module assignments**:
- Clock: `@accent-primary`
- Network: `@accent-info` (connected), `@fg-muted` (disconnected)
- Battery: `@accent-success` (normal), `@accent-warning` (~20%), `@accent-error` (<10%), `@accent-info` (charging), `@accent-primary` (plugged)
- Audio: `@accent-highlight`, `@fg-muted` (muted)
- Bluetooth: `@accent-info`, `@accent-highlight` (connected), `@fg-muted` (disabled)
- Backlight: `@accent-warning`
- Workspaces: `@fg-muted` (inactive), `@accent-primary` bg + `@fg-contrast` text (active/hover), `@accent-error` bg (urgent)
- Window title: `@fg-secondary`

**Details**: See `waybar/CLAUDE.md`

### Dunst (`dunst/dunstrc.tmpl`)

**Format**: INI with direct hex values (no `@variable` support)
**Variables used**: 4 (bg-primary, fg-primary, accent-primary, accent-error)

**Urgency mappings**:
- Low: `@bg-primary` background, `@fg-primary` foreground, `@accent-primary` frame
- Normal: `@bg-primary` background, `@fg-primary` foreground, `@accent-primary` frame
- Critical: `@bg-primary` background, `@fg-primary` foreground, `@accent-error` frame

**Details**: See `dunst/CLAUDE.md`

### Wofi (`wofi/style.css.tmpl`)

**Format**: GTK CSS with `@variable` references
**Variables used**: ~8 (backgrounds, foregrounds, accent-primary)

**Element mappings**:
- Window: `@bg-primary`, `@fg-primary`
- Input field: `@bg-secondary`, `@fg-primary`
- Selected item: `@accent-primary` bg, `@fg-contrast` text
- Hover: `@bg-secondary`

**Details**: See `wofi/CLAUDE.md`

### Wlogout (`wlogout/style.css.tmpl`)

**Format**: GTK CSS with `@variable` references
**Variables used**: ~10 (backgrounds, foregrounds, all 8 accents)

**Button assignments**:
- Lock: `@accent-tertiary` (orange/peach)
- Logout: `@accent-warning` (yellow)
- Suspend: `@accent-primary` (blue)
- Hibernate: `@accent-highlight` (violet/purple)
- Reboot: `@accent-info` (cyan/teal)
- Shutdown: `@accent-error` (red)

**Details**: See `wlogout/CLAUDE.md`

### Hyprland (`hyprland.conf`)

**Format**: Hyprland variables (`$var = rgba(hex)`)
**Variables used**: 2 (activeBorder, inactiveBorder)

**Mappings**:
- `$activeBorder`: `@accent-primary` equivalent (with opacity)
- `$inactiveBorder`: `@fg-muted` equivalent (with opacity)

**Integration**: `general.conf` uses `col.active_border = $activeBorder`

### Ghostty (`ghostty/config`)

**Format**: Palette configuration (`palette = N=#hex`)
**Variables used**: None (ANSI terminal conventions, not semantic)

**Integration**: `theme = current` (symlink to `~/.config/ghostty/themes/current`)

### Hyprlock (`themes/*/hyprlock.conf`)

**Format**: Hyprlock configuration with RGB values
**Variables used**: TBD (border colors, text colors)

**Integration**: Sourced by hyprlock at runtime

---

## Theme Switching Methods

### Manual Switching

**CLI functions** (Zsh):
```bash
theme switch <theme-name>    # Switch to theme
theme list                   # List available themes
```

**CLI wrapper**:
```bash
theme-menu                   # Interactive theme selector (gum)
```

**Implementation**: `~/.local/lib/scripts/desktop/theme-switcher.sh.tmpl`

**Process**:
1. Updates `~/.config/themes/current` symlink
2. Reloads Waybar: `killall waybar && waybar &`
3. Reloads Dunst: `killall dunst` (auto-restarts)
4. Reloads Hyprland: `hyprctl reload`
5. Updates wallpaper to match theme mood

### Automated Solar Switching (Darkman)

**Service**: `darkman.service` (systemd user)
**Config**: `~/.config/darkman/config.yaml` (lat/long for sunrise/sunset)

**Hooks**:
- `~/.local/share/dark-mode.d/01-switch-theme.sh` → Switches to dark variant
- `~/.local/share/light-mode.d/01-switch-theme.sh` → Switches to light variant

**Commands**:
```bash
darkman get           # Show current mode (light/dark)
darkman set light     # Manual switch to light
darkman set dark      # Manual switch to dark
darkman toggle        # Toggle between light/dark
```

**Auto-transition**: At sunrise/sunset based on geo coordinates

### Keybindings (Hyprland)

**Toggle light/dark**: `Super+Shift+Y` → `darkman toggle`
**Theme menu**: `Super+Shift+Ctrl+Space` → `theme-menu`

**Config**: `~/.config/hypr/conf/bindings.conf.tmpl`

---

## Theme Style Guides Summary

### Catppuccin

**Philosophy**: Community-driven pastel theme, middle ground between low/high contrast
**Palette**: 26 colors (4 flavors: Latte, Frappé, Macchiato, Mocha)
**Structure**: Base/Mantle/Crust + 3 surface layers + 3 overlay layers + 6 text tones + 14 accents
**Key principle**: Legibility always comes first (deviate for contrast)
**Docs**: https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md

### Rose Pine

**Philosophy**: Natural pine, faux fur, soho vibes for classy minimalist
**Palette**: 15 colors (3 variants: Main, Moon, Dawn)
**Structure**: Base/Surface/Overlay + Muted/Subtle/Text + 6 semantic accents + 3 highlight layers
**Key principle**: Dual-purpose colors (visual + functional), nature-inspired names
**Docs**: https://rosepinetheme.com/palette

### Gruvbox

**Philosophy**: Retro groove color scheme, easily distinguishable, pleasant for eyes
**Palette**: 3 contrast levels (hard/medium/soft) + bright/neutral accent sets
**Structure**: 7 dark tones + 7 light tones + 2 grays + 7 bright accents + 7 neutral accents + 7 faded
**Key principle**: Adjustable contrast for ambient lighting/display/accessibility
**Docs**: https://github.com/morhetz/gruvbox

### Solarized

**Philosophy**: Precision colors for machines and people (CIELAB-based)
**Palette**: 16 colors (symmetric light/dark design)
**Structure**: 8 base monotones (bidirectional) + 8 hue-based accents
**Key principle**: Selective contrast (reduce brightness, retain hue), symmetric relationships, scientifically optimized
**Docs**: https://ethanschoonover.com/solarized/

---

## Asset Organization (Wallpapers, Icons, Cursors, Fonts)

### Directory Structure

```
~/.config/themes/
├── wallpapers/         # Wallpaper images
│   ├── landscapes/
│   ├── abstract/
│   └── minimal/
├── icons/              # Icon themes
├── cursors/            # Cursor themes
└── fonts/              # Custom fonts
```

### Wallpaper System

**Architecture**: Theme-integrated wallpaper collections (color-matched per theme)
**Storage**: `~/.config/wallpapers/{theme}/` → direct from chezmoi external (no symlinks)
**Distribution**: Git repository via chezmoi external (`.chezmoiexternal.yaml`)
**Formats**: JPG, PNG, WEBP

**Wallpaper selection**:
```bash
random-wallpaper    # Selects from current theme's wallpaper directory
set-wallpaper /path/to/wallpaper.jpg
```

**Rotation**: Systemd timer cycles through current theme's collection only (30-minute interval)

**External repository approach**:
- Repository: Personal git repo with theme subdirectories
- Organization: One-time color-matching using `~/.local/lib/scripts/media/organize-wallpapers-by-color.sh`
- Distribution: Chezmoi pulls entire repo directly to `~/.config/wallpapers/`
- Update: `chezmoi update --refresh-externals` pulls latest wallpapers
- Benefits: Lightweight dotfiles repo, version-controlled wallpapers, reproducible

**Color matching** (one-time organization):
- Wallust extracts dominant colors from each wallpaper (16-color palette)
- Python script calculates Delta E (LAB color space) distance to theme palettes
- Round-robin assignment ensures balanced distribution across themes
- Wallpapers assigned to best-matching theme (threshold: 50/100, configurable via `--threshold`)
- Unmatched wallpapers saved for manual review

**Color generation**: Wallust is **intentionally disabled** in favor of static theme colors
- Rationale: Consistent semantic variables across applications
- Usage: Color matching for organization only (not runtime)
- Alternative: Enable wallust for dynamic extraction if desired (see set-wallpaper.sh comments)

### Icon Themes

**Location**: `themes/icons/`
**Structure**:
```
icons/
└── theme-name/
    ├── index.theme
    ├── scalable/
    └── symbolic/
```

**Application**: GTK/Qt apps via `~/.config/gtk-3.0/settings.ini`

### Cursor Themes

**Location**: `themes/cursors/`
**Structure**:
```
cursors/
└── theme-name/
    ├── index.theme
    └── cursors/
```

**Application**: X11/Wayland via `~/.config/hypr/conf/environment.conf`

### Font Organization

**Location**: `themes/fonts/`
**Categories**:
- `monospace/` - Terminal, code
- `sans-serif/` - UI, documents
- `serif/` - Documents
- `icon-fonts/` - Icon glyphs

**Formats**: TTF, OTF

### Integration Points

- **Wallust**: `~/.config/wallust/` (color extraction)
- **Wallpaper scripts**: `~/.local/lib/scripts/media/` (random-wallpaper, set-wallpaper)
- **Systemd timer**: `~/.config/systemd/user/wallpaper-cycle.timer` (rotation)
- **GTK**: `~/.config/gtk-3.0/settings.ini` (icon theme)
- **Hyprland**: `~/.config/hypr/conf/environment.conf` (cursor theme)
