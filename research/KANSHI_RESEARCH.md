# Kanshi Research Notes

Investigated for future implementation of automatic monitor configuration.

## Summary

Kanshi is a Wayland display configuration tool (autorandr equivalent) that automatically applies profiles based on connected monitors. Investigated for dock/undock scenarios on laptop.

## Key Findings

### Profile Matching Logic
- Evaluates profiles top-to-bottom in config file
- First matching profile wins (ALL outputs must be connected)
- EDID-based matching is most reliable (portable across docks)

### Syntax Example
```config
profile desktop {
    output "MAKE MODEL SERIAL" {
        mode 3840x2160@144
        position 0,0
        scale 1.25
        transform, normal
    }
    exec sleep 2 && ~/.local/lib/scripts/desktop/executable_recover-workspaces.sh
}
```

### Integration with Hyprland
```conf
# Add to autostart.conf
exec-once = sleep 2 && kanshi
```

### Limitations Discovered

1. **No automatic workspace migration** - Workspaces on disconnected monitors don't move automatically
2. **Manual recovery required** - Must call `split:grabroguewindows` after profile changes
3. **Profile matching all-or-nothing** - Must match ALL listed outputs or none apply
4. **Race condition possible** - Kanshi may start before Hyprland is ready (solved with sleep 2)

### Discovery Workflow

```bash
# Get monitor EDIDs
hyprctl monitors

# Alternative
kanshi --list-outputs
```

### Best Practices

1. Use EDID-based identification (not connector names)
2. Add delays before workspace recovery (1-3 seconds)
3. Profile priority: specific → generic → fallback
4. Use absolute paths in `exec` commands

## Current Monitor Setup

**Desktop**:
- Primary: DP-1 (GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 21411B000071)
  - 3840x2160@144Hz, scale 1.25, position 0x0, transform normal
- Secondary: HDMI-A-1 (BNQ BenQ GW2765 W9F03010019)
  - 2560x1440@59.95Hz, scale 1.0, position 3072x144, transform 1 (portrait)

**EDID Format**:
- Primary: `"GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 21411B000071"`
- Secondary: `"BNQ BenQ GW2765 W9F03010019"`

## References

- Official docs: https://gitlab.freedesktop.org/emersion/kanshi
- Arch Wiki: https://wiki.archlinux.org/title/Kanshi
- GitHub issues: Monitor hot-plug discussions

## Implementation Checklist (Future)

- [ ] Test Kanshi with desktop profile
- [ ] Test Kanshi with laptop profile
- [ ] Test dock/undock scenarios
- [ ] Verify automatic profile switching
- [ ] Test workspace recovery after monitor changes
- [ ] Create Kanshi profiles for home/office docks
- [ ] Integrate with lid close handling

## Known Issues from Research

1. Issue: Windows pile into single workspace after recovery
   - Workaround: Manual reorganization after `grabroguewindows`

2. Issue: Profile not applying
   - Fix: Check EDID strings match exactly (case-sensitive)
   - Fix: `journalctl --user -u kanshi` for diagnostics

3. Issue: Workspace numbering resets after sleep
   - Fix: Explicitly move workspace 1 to primary monitor in profile `exec`

## Decision to Defer

**Why deferred**:
- Current setup works well enough with manual monitor changes
- Want to test hyprsplit thoroughly before adding more complexity
- Kanshi adds another daemon to manage and debug
- Current manual workflow is acceptable for now

**When to revisit**:
- After comfortable with hyprsplit behavior
- If frequent dock/undock becomes annoying
- If manual workspace recovery becomes tedious

## Example Profile Configurations

### Desktop Profile (2 monitors)
```config
profile desktop {
    # Primary Monitor (4K @ 144Hz, 1.25x scale, left)
    output "GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 21411B000071" {
        mode 3840x2160@144
        position 0,0
        scale 1.25
        transform, normal
    }

    # Secondary Monitor (1440p @ 60Hz, portrait, right)
    output "BNQ BenQ GW2765 W9F03010019" {
        mode 2560x1440@60
        position 3072,144
        scale 1.0
        transform, 1
    }

    # Recover workspaces after profile change
    exec sleep 2 && ~/.local/lib/scripts/desktop/executable_recover-workspaces.sh
}
```

### Laptop Profile (Undocked)
```config
profile laptop {
    # Built-in display (laptop EDID goes here)
    output "LAPTOP_MAKE LAPTOP_MODEL LAPTOP_SERIAL" {
        mode preferred
        scale 2.0
        position 0,0
    }
}
```

### Docked Profile (Example for future)
```config
profile docked {
    output "LAPTOP_MAKE LAPTOP_MODEL LAPTOP_SERIAL" disable

    output "DOCK_MAKE DOCK_MODEL DOCK_SERIAL" {
        mode 1920x1080@60
        position 0,0
        scale 1.0
        transform, normal
    }

    exec sleep 2 && ~/.local/lib/scripts/desktop/executable_recover-workspaces.sh
}
```
