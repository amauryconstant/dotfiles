# Themes - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/themes/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Theme system**: Semantic variable abstraction (16 variables)
- **8 variants**: Catppuccin (latte/mocha), Rose Pine (dawn/moon), Gruvbox (light/dark), Solarized (light/dark)
- **Switching**: `theme switch <name>`, darkman (solar), Super+Shift+Y (toggle), Super+Shift+Ctrl+Space (menu)
- **Location**: `~/.config/themes/current` → symlink to active theme
- **Apps**: Desktop (7), CLI tools (6), Shell scripts (8 via gum-ui)
- **Style guides**: Each theme has `STYLE-GUIDE.md` with color selection methodology

---

## Architecture

**Symlink switching**: `~/.config/themes/current` → active theme directory

**Per-theme files**:
- **Desktop**: `waybar.css`, `dunst.conf`, `ghostty.conf`, `hyprland.conf`, `hyprlock.conf`, `wlogout.css`, `wofi.css`
- **CLI**: `bat.conf`, `broot.hjson`, `btop.theme`, `lazygit.yml`, `starship.toml`, `yazi.toml`
- **Docs**: `STYLE-GUIDE.md`

**Integration**:
- **Desktop apps**: Import via `@import`, `!include`, or `source` directives
- **CLI tools**: Symlinks in `~/.config/{app}/` → `themes/current/{app-config}`

---

## Semantic Variable Schema

**24 variables** organized into 3 categories (Phase 3 - expanded system):

### Background Hierarchy (4)

| Variable | Role | Usage | **Required Text Color** |
|----------|------|-------|-------------------------|
| `@bg-primary` | Main background | Bars, windows, primary canvas | `@fg-primary` or `@fg-secondary` |
| `@bg-secondary` | Elevated surfaces | Hover states, cards, inputs | **ALWAYS @fg-primary** |
| `@bg-tertiary` | Popovers | Notifications, tertiary elevation | `@fg-primary` |
| `@bg-overlay` | Modal overlays | Dialogs, semi-transparent | `@fg-primary` |

### Foreground/Text Hierarchy (4)

| Variable | Role | Usage |
|----------|------|-------|
| `@fg-primary` | Primary text | Body content, main labels |
| `@fg-secondary` | Secondary text | Subtitles, window title |
| `@fg-muted` | Disabled/inactive | Unfocused, low contrast |
| `@fg-contrast` | High contrast | Text on colored backgrounds |

### Accent Colors (16 semantic roles - Phase 1+2+3)

**Core Accents (8 - Phase 1)**:

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-primary` | Active states | Clock, active workspace, battery plugged |
| `@accent-info` | Connectivity | Network, Bluetooth, battery charging |
| `@accent-success` | Success states | Battery normal, positive indicators |
| `@accent-warning` | Warnings | Battery low (<20%), backlight, caution |
| `@accent-error` | Errors/urgent | Battery critical (<10%), urgent workspace |
| `@accent-highlight` | Secondary actions | Audio/PulseAudio, special states |
| `@accent-secondary` | Tertiary actions | Alternative interactive elements |
| `@accent-tertiary` | Quaternary | Lock, logout buttons |

**Extended Accents (8 - Phase 2+3)**:

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-modification` | File changes | Git diffs, search highlights, wofi search match |
| `@accent-border` | Focus indicators | Active borders (Hyprland), focus rings, input borders |
| `@accent-performance` | System metrics | Disk usage, CPU, memory modules |
| `@accent-media` | Media controls | Audio, video, media player modules |
| `@accent-subtle` | Low priority | Cursors, subtle hints, disabled secondary |
| `@accent-alternative` | Alternative | Tertiary navigation, wlogout extra buttons |
| `@accent-special` | Special states | Custom modules, rare indicators |
| `@accent-urgent-secondary` | Moderate urgency | Battery 20-30%, moderate warnings |

**Hover Variants (4 - Phase 3)**:

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-info-hover` | Network hover | 10% opacity version of accent-info |
| `@accent-highlight-hover` | Audio hover | 10% opacity version of accent-highlight |
| `@accent-warning-hover` | Backlight hover | 10% opacity version of accent-warning |
| `@accent-success-hover` | Battery hover | 10% opacity version of accent-success |

---

## Contrast Guidelines

### CRITICAL RULE: Text on Elevated Surfaces

Elevated surfaces (`@bg-secondary`, `@bg-tertiary`) MUST use `@fg-primary` for ALL text and icons.

**DO NOT** use `@fg-secondary` on elevated surfaces - this creates insufficient contrast (4.0-4.5:1) that fails WCAG AA standards (4.5:1 required).

#### Correct Patterns

| Background Surface | Text Color | Typical Contrast | WCAG Status | Use Case |
|-------------------|------------|------------------|-------------|----------|
| `@bg-primary` | `@fg-primary` | 8.0-9.0:1 | ✓✓ AAA | Primary content |
| `@bg-primary` | `@fg-secondary` | 4.0-5.5:1 | ± AA (theme-dependent) | Less critical text |
| **`@bg-secondary`** | **`@fg-primary`** | **7.0:1+** | **✓ AA** | **Elevated surfaces** |
| `@bg-tertiary` | `@fg-primary` | 6.0:1+ | ✓ AA | Popovers, notifications |

#### Incorrect Patterns (DO NOT USE)

| Background Surface | Text Color | Typical Contrast | Problem |
|-------------------|------------|------------------|---------|
| ~~`@bg-secondary`~~ | ~~`@fg-secondary`~~ | ~~4.0-4.5:1~~ | Both "secondary" = low contrast |
| ~~`@bg-tertiary`~~ | ~~`@fg-muted`~~ | ~~3.0-4.0:1~~ | Barely readable |

### Application Examples

**Correct (Wofi, Wlogout):**
```css
#input {
  background-color: @bg-secondary;  /* Elevated surface */
  color: @fg-primary;                /* Primary text ✓ */
}
```

**Incorrect (Firefox prior to fix):**
```css
.tabbrowser-tab[selected] {
  background-color: var(--bg-secondary);  /* Elevated surface */
  /* Missing: color: var(--fg-primary); ✗ */
}
```

### Theme-Specific Contrast Ratios

| Theme | FG_PRIMARY on BG_SECONDARY | FG_SECONDARY on BG_SECONDARY | Status |
|-------|---------------------------|------------------------------|--------|
| Catppuccin Latte | 5.53:1 | 4.05:1 | Use PRIMARY only |
| Catppuccin Mocha | 9.26:1 | 7.10:1 | PRIMARY preferred |
| Gruvbox Light | 7.78:1 | 6.43:1 | PRIMARY preferred |
| Gruvbox Dark | 8.59:1 | 6.76:1 | PRIMARY preferred |
| Rose Pine Dawn | 7.00:1 | 4.23:1 ✗ | Use PRIMARY only |
| Rose Pine Moon | 5.18:1 | 4.46:1 ✗ | Use PRIMARY only |
| Solarized Light | 4.99:1 | 4.39:1 ✗ | Use PRIMARY only |
| Solarized Dark | 5.61:1 | 4.86:1 | PRIMARY preferred |

**Key:** ✗ = Fails WCAG AA if using FG_SECONDARY

**Rationale:** Combining "secondary" background with "secondary" text creates insufficient contrast. Both variables are designed to be subtle; pairing them results in readability issues, particularly visible in Firefox (URL bar icons, selected tabs) on themes like Rose Pine Dawn.

---

## Semantic Mappings

**Reference**: See individual theme `STYLE-GUIDE.md` files for:
- Complete hex code mappings
- Design principles
- Color selection methodology
- Syntax highlighting patterns
- Variant adaptation strategies

**Quick lookup**: Each theme directory contains complete semantic variable definitions in `waybar.css`

---

## Theme Switching

**Manual**: `theme switch <name>`, `theme list`, `theme-menu`
**Solar auto**: darkman service (sunrise/sunset transitions)
**Keybindings**: Super+Shift+Y (toggle), Super+Shift+Ctrl+Space (menu)

**Process**: Updates symlink → reloads Waybar/Dunst/Hyprland → updates wallpaper

---

## Style Guides

Each theme has `STYLE-GUIDE.md` with methodology-focused documentation:

**Catppuccin**: 14-accent pastel, legibility-first, colorfulness philosophy
**Rose Pine**: Minimalist natural, dual-purpose colors, nature-inspired
**Gruvbox**: Warm retro groove, easily distinguishable, adjustable contrast
**Solarized**: CIELAB precision, symmetric design, selective contrast

**Format**: Design Principles → Color Selection Framework → Context-Specific → Variant Adaptation → Palette → Terminal → Validation → References

---

## Wallpapers

**System**: Theme-integrated collections, color-matched per theme via Delta E (LAB)
**Storage**: `~/.config/wallpapers/{theme}/` from chezmoi external
**Selection**: `random-wallpaper`, `set-wallpaper`
**Rotation**: Systemd timer (30 min)

**Organization**: One-time color matching using `organize-wallpapers-by-color.sh`
**Note**: Wallust disabled (static theme colors, not dynamic extraction)

---

## CLI Tool Integration

**7 CLI tools** themed via symlink switching:

| Tool | Config File | Symlink Location | Purpose |
|------|-------------|------------------|---------|
| **bat** | `bat.conf` | `~/.config/bat/config` | Syntax highlighting theme selection |
| **broot** | `broot.hjson` | `~/.config/broot/skin.hjson` | File tree skin colors |
| **btop** | `btop.theme` | `~/.config/btop/color_theme` | System monitor color scheme |
| **lazygit** | `lazygit.yml` | `~/.config/lazygit/config.yml` | Git TUI theme colors |
| **opencode** | `opencode.json` | `~/.config/opencode/themes/current.json` | TUI theme via custom JSON |
| **starship** | `starship.toml` | `~/.config/starship.toml` | Shell prompt colors/symbols |
| **yazi** | `yazi.toml` | `~/.config/yazi/theme.toml` | File manager theme |

**Special handling**:
- **bat**: Requires cache rebuild via `run_onchange_after_rebuild_bat_cache.sh.tmpl`
- **bat themes**: Rose Pine variants use custom `.tmTheme` files (`~/.config/bat/themes/`)
- **starship**: Theme-specific prompt symbols and color schemes
- **broot**: Skin-based color system with syntax highlighting
- **btop**: Direct color code mappings (no semantic variables)
- **lazygit**: Theme colors integrated with git status highlighting
- **yazi**: File type icons and selection colors

**Switching**: Symlinks automatically update when `theme switch` runs

---

## Shell Script Integration (CLI Tools)

**7th integration category** - System CLI tools via gum-ui library

**Implementation**: Shell-sourceable `colors.sh` files in each theme

### colors.sh Format

```bash
#!/usr/bin/env sh
# Theme colors for shell scripts
# Auto-generated from waybar.css

# Background Hierarchy (4)
readonly BG_PRIMARY="#hex"      # Main background
readonly BG_SECONDARY="#hex"    # Elevated surfaces
readonly BG_TERTIARY="#hex"     # Popovers
readonly BG_OVERLAY="#hex"      # Modal overlays

# Foreground Hierarchy (4)
readonly FG_PRIMARY="#hex"      # Primary text
readonly FG_SECONDARY="#hex"    # Secondary text
readonly FG_MUTED="#hex"        # Disabled/inactive
readonly FG_CONTRAST="#hex"     # High contrast

# Core Accents (8)
readonly ACCENT_PRIMARY="#hex"  # Primary actions
# ... (full 24 variables)

# Export all for subshells
export BG_PRIMARY BG_SECONDARY ...
```

### Usage in Scripts

**Automatic loading** (via gum-ui):
```bash
#!/usr/bin/env bash
. "$UI_LIB"  # Sources theme colors automatically

ui_success "Task complete"  # Uses ACCENT_SUCCESS
ui_error "Failed"            # Uses ACCENT_ERROR
```

**Direct sourcing**:
```bash
. ~/.config/themes/current/colors.sh
echo "${ACCENT_PRIMARY}Primary color${FG_PRIMARY}"
```

### Consumer Scripts

**8 system CLI tools** use theme colors via gum-ui:
1. package-manager (3,069 lines)
2. system-health
3. system-maintenance
4. system-health-dashboard
5. troubleshoot
6. regenerate-ssh-key
7. tailscale (network helper)
8. organize-wallpapers-by-color

### Theme Reload Behavior

**New shells only** - CLI tools pick up active theme on startup
- Theme switch updates symlink → new shells source new colors
- Running shells keep old colors (acceptable - CLI tools are quick-run)
- No live reload needed (theme changes infrequent)

### Generation

**Automated** via `generate-theme-shell-colors.sh`:
- Reads `waybar.css` for each theme
- Extracts `@define-color` variables
- Converts CSS to shell format
- Validates shell syntax
- Creates all 8 theme color files

**One-time use** - color files committed to repo
