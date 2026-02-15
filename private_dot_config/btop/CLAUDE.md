# btop Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/btop/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

---

## Quick Reference

- **Config**: `btop.conf` (static — not a template)
- **Theme symlink**: `symlink_color_theme` → `../themes/current/btop.theme`
- **Active theme**: `~/.config/btop/color_theme` → `~/.config/themes/current/btop.theme`
- **8 variants**: One `btop.theme` per theme in `private_dot_config/themes/{variant}/`
- **No semantic CSS variables**: btop uses direct hex codes (unlike Waybar)

---

## Symlink Mechanism

```
~/.config/btop/color_theme
    → ~/.config/themes/current/btop.theme
    → ~/.config/themes/{active-variant}/btop.theme
```

Switching themes via `theme switch <name>` updates the `current` symlink; btop picks up new colors on next launch (no restart needed if btop is running — reload with `ESC → Options`).

---

## 37-Property → Semantic Variable Mapping

Cross-reference hex values against the variant's `waybar.css` `@define-color` declarations.

| btop property | Semantic variable | Notes |
|---------------|-------------------|-------|
| `main_bg` | `@bg-primary` | Exact hex of bg-primary |
| `main_fg` | `@fg-primary` | Main text |
| `title` | `@fg-primary` | Box title text |
| `hi_fg` | `@accent-primary` | Keyboard shortcut highlights |
| `selected_bg` | `@bg-tertiary` | Selected row background |
| `selected_fg` | `@accent-primary` | Selected row text |
| `inactive_fg` | `@fg-muted` | Disabled/unfocused text |
| `graph_text` | `@accent-tertiary` | Overlay labels on graphs |
| `meter_bg` | `@bg-tertiary` | Percentage bar background |
| `proc_misc` | `@accent-tertiary` | Process misc status text |
| `cpu_box` | `@accent-highlight` | CPU box outline |
| `mem_box` | `@accent-success` | Memory box outline |
| `net_box` | `@accent-error` | Network box outline |
| `proc_box` | `@accent-primary` | Process box outline |
| `div_line` | `@fg-muted` (dimmer) | Internal divider lines |
| `temp_start` | `@accent-success` | Temperature gradient: cool |
| `temp_mid` | `@accent-warning` | Temperature gradient: warm |
| `temp_end` | `@accent-error` | Temperature gradient: hot |
| `cpu_start` | `@accent-info` | CPU gradient: low usage |
| `cpu_mid` | `@accent-secondary` | CPU gradient: mid usage |
| `cpu_end` | `@accent-primary` | CPU gradient: high usage |
| `free_start` | `@accent-highlight` | Free meter start |
| `free_mid` | `@accent-secondary` | Free meter mid |
| `free_end` | `@accent-primary` | Free meter end |
| `cached_start` | `@accent-secondary` | Cached meter start |
| `cached_mid` | `@accent-primary` | Cached meter mid |
| `cached_end` | `@accent-secondary` | Cached meter end |
| `available_start` | `@accent-tertiary` | Available meter start |
| `available_mid` | `@accent-error` (lighter) | Available meter mid |
| `available_end` | `@accent-error` | Available meter end |
| `used_start` | `@accent-success` | Used meter start |
| `used_mid` | `@accent-info` | Used meter mid |
| `used_end` | `@accent-secondary` | Used meter end |
| `download_start` | `@accent-tertiary` | Download graph start |
| `download_mid` | `@accent-error` (lighter) | Download graph mid |
| `download_end` | `@accent-error` | Download graph end |
| `upload_start` | `@accent-success` | Upload graph start |
| `upload_mid` | `@accent-info` | Upload graph mid |
| `upload_end` | `@accent-secondary` | Upload graph end |
| `process_start` | `@accent-secondary` | Process gradient start |
| `process_mid` | `@accent-secondary` (lighter) | Process gradient mid |
| `process_end` | `@accent-highlight` | Process gradient end |

---

## Gradient Design Guide

### Temperature: green → yellow → red

Conveys thermal state intuitively. Maps to:
- `temp_start` = `accent-success` (safe/cool)
- `temp_mid` = `accent-warning` (warm, attention)
- `temp_end` = `accent-error` (hot, critical)

### CPU: cool → warm

Uses the cooler accents of the theme palette progressing toward the primary accent.
- Dark themes: teal/sapphire → lavender/blue
- Light themes: teal/sapphire → iris/blue

### Memory: semantic tiers

- **used**: success (green) → info (teal/sky) — healthy consumption
- **available**: peach → maroon/red — resource pressure indicator
- **free**: highlight (mauve/purple) → primary (blue) — available capacity

### Network: mirrored with upload/download

- **download**: peach → red (intake / consumption)
- **upload**: green → sky (output / share)

---

## Light Theme Notes

Light themes (`catppuccin-latte`, `gruvbox-light`, `rose-pine-dawn`, `solarized-light`) require:

- `main_bg` = exact hex of `@bg-primary` (the light color)
- `main_fg` = dark text from `@fg-primary` (must contrast against light bg)
- `inactive_fg` = mid-tone from `@fg-muted` (not too light, must be readable)
- Box outlines (`cpu_box` etc.) = saturated accents from the light palette

**Key check**: On light themes, all text properties (`main_fg`, `title`, `graph_text`, `proc_misc`) must produce ≥4.5:1 contrast against `main_bg`.

---

## Audit Checklist (for future maintainers)

When updating a theme variant:

1. Open `waybar.css` for the variant → copy exact hex values
2. Verify `main_bg` = `@bg-primary` hex
3. Verify `main_fg` = `@fg-primary` hex
4. Verify `inactive_fg` = `@fg-muted` hex
5. Verify box outline colors use distinct semantic roles:
   - cpu_box ≠ mem_box ≠ net_box ≠ proc_box
6. Verify gradient triplets are visually distinguishable
7. Launch btop and cycle through views to confirm rendering
8. For light themes: confirm readability against light background

**Cross-reference command**:
```bash
grep "@define-color" ~/.config/themes/{variant}/waybar.css
```
