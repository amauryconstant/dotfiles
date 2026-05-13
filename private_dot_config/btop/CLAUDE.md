# btop Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/btop/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

---

## Quick Reference

- **Config**: `btop.conf` (static — not a template)
- **Theme symlink**: `themes/symlink_color_theme.theme` → `../../themes/current/btop.theme`
- **Active theme**: `~/.config/btop/themes/color_theme.theme` → `~/.config/themes/current/btop.theme`
- **8 variants**: One `btop.theme` per theme in `private_dot_config/themes/{variant}/`
- **No semantic CSS variables**: btop uses direct hex codes (unlike Waybar)

---

## Symlink Mechanism

```
~/.config/btop/themes/color_theme.theme
    → ~/.config/themes/current/btop.theme
    → ~/.config/themes/{active-variant}/btop.theme
```

Switching themes via `theme switch <name>` updates the `current` symlink; btop picks up new colors on next launch (no restart needed if btop is running — reload with `ESC → Options`).

---

## Semantic Variable Mapping (Summary)

Cross-reference hex values against the variant's `waybar.css` `@define-color` declarations.

**Key mappings**: `main_bg` → `@bg-primary`, `main_fg` → `@fg-primary`, `inactive_fg` → `@fg-muted`, box outlines (cpu/mem/net/proc) → distinct accent colors, gradient triplets → semantic gradient (success→warning→error for temp; info→secondary→primary for CPU).

**Cross-reference command**:
```bash
grep "@define-color" ~/.config/themes/{variant}/waybar.css
```

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
