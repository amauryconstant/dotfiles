# hyprland-autoname-workspaces Research Notes

Investigated for future implementation of automatic workspace naming.

## Summary

hyprland-autoname-workspaces automatically renames workspaces based on running applications. Shows app icons in Waybar instead of numbers.

## Key Findings

### How It Works
- Runs as systemd user service: `systemctl --user enable hyprland-autoname-workspaces.service`
- Watches Hyprland events for workspace changes
- Updates workspace names with app icons (uses Nerd Font icons)
- Works with Waybar's `hyprland/workspaces` module

### Configuration Example
```toml
[icons]
DEFAULT = "{class}: {title}"

# Web browsers
"firefox" = ""
"chromium" = ""

# Development
"code-oss.vscode" = ""
"jetbrains-.+" = ""

[exclude]
"(?i)fcitx" = ".*"
"Waybar" = ".*"
"wofi" = ".*"
"dunst" = ".*"
```

### Integration with Waybar
```json
"hyprland/workspaces": {
    "format": "{name}"  // Uses autoname-workspaces output
}
```

## Installation

```bash
# From AUR
paru -S hyprland-autoname-workspaces-git

# Enable service
systemctl --user enable --now hyprland-autoname-workspaces.service
```

## Benefits Discovered

1. **Visual workspace identification** - Know what's on each workspace at a glance
2. **Nerd Font icons** - Matches system theme
3. **Regex flexibility** - Can match multiple apps with one pattern
4. **Exclude list** - Don't pollute workspace names with system apps

## Limitations Discovered

1. **AUR package reliability** - Git-based package, not in official repos
2. **Icon configuration required** - Must manually specify icons for each app
3. **No workspace name persistence** - Renames are transient (reset on Hyprland restart)
4. **Potential conflicts** - May interfere with manual `renameworkspace` dispatchers
5. **Service management overhead** - Another daemon to monitor and debug

## Icon Strategy

### Recommended Icons
- Use empty string for Nerd Font icons (let app decide icon)
- OR use specific icons: "" for consistent styling

### Exclusion Patterns

```toml
[exclude]
"(?i)fcitx" = ".*"
"(?i)im-chooser" = ".*"
"Waybar" = ".*"
"wofi" = ".*"
"dunst" = ".*"
```

## Testing Observations (From Research)

- Works well with standard desktop apps (Firefox, VSCode, Discord)
- Some GTK apps may show incorrect class names (requires testing)
- Multiple windows on workspace: shows first/primary window's icon
- Empty workspaces: shows number (default fallback)

## Decision to Defer

**Why deferred**:
- Current workspace numbering (1-10) is familiar and predictable
- Want to test hyprsplit behavior first before adding visual complexity
- Icon configuration is manual work to maintain
- Can achieve similar benefits with semantic window rules (apps auto-assign to workspaces)

**When to revisit**:
- After comfortable with hyprsplit per-monitor workspaces
- If workspace identification becomes confusing with numbers only
- If working with many different applications daily
- If want more visual feedback in Waybar

## Future Implementation Steps

1. Install package: `paru -S hyprland-autoname-workspaces-git`
2. Create `~/.config/hyprland-autoname-workspaces/config.toml`
3. Enable service: `systemctl --user enable --now ...`
4. Configure icons for commonly used apps
5. Configure exclusion list for system apps
6. Test with Waybar workspace module
7. Verify icons display correctly for different applications

## Current Workspace Organization

With hyprsplit, workspaces are now semantically organized:

- **Workspace 1 (web)**: Firefox, Chromium, Chrome
- **Workspace 2 (dev)**: VSCode, VSCodium, JetBrains IDEs
- **Workspace 3 (term)**: Ghostty, Kitty, Alacritty
- **Workspace 4 (chat)**: Discord, WebCord, Teams, Signal
- **Workspace 5 (media)**: Spotify, VLC, mpv
- **Workspace 6 (utils)**: pavucontrol, Blueman, system settings
- **Workspace 7 (ref)**: Obsidian, Logseq, Thunderbird
- **Workspace 8 (games)**: Steam, Lutris, Heroic
- **Workspace 9 (design)**: GIMP, Inkscape, Blender
- **Workspace 10 (scratch)**: Calculator, Clocks

This provides visual organization without autoname-workspaces.
