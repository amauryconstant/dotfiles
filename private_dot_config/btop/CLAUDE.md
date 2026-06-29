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
- **Per-theme**: One `btop.theme` per theme in `private_dot_config/themes/{variant}/`
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

When editing a variant's `btop.theme`, keep box outlines distinct per role (`cpu_box ≠ mem_box ≠ net_box ≠ proc_box`) and gradient triplets visually distinguishable — btop has no semantic indirection, so every value is a literal hex copied from `waybar.css`.
