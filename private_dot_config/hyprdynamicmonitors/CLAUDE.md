# HyprDynamicMonitors - Desktop Configuration

**Status**: Desktop-only configuration, power events disabled.

## Quick Reference

- **TUI**: `hyprdynamicmonitors tui` - Interactive monitor configuration
- **Validate**: `hyprdynamicmonitors validate` - Check config syntax
- **Logs**: `journalctl --user -u hyprdynamicmonitors` - Debug issues

## Desktop Setup

### Current Profile

**desktop_dual**: Dual monitor setup (Gigabyte M32U + BenQ GW2765)
- Primary: Gigabyte M32U (4K @ 144Hz, 1.25x scale, position: 0x0)
- Secondary: BenQ GW2765 (1440p @ 60Hz, portrait, transform 1)
- Matches by monitor **description** (port-agnostic)
- Generated config: `~/.config/hypr/monitors.conf`

### Initial Setup (One-time)

```bash
# 1. Install packages
package-manager sync

# 2. Enable prepare service (runs before Hyprland)
systemctl --user enable hyprdynamicmonitors-prepare.service

# 3. Enable main service
systemctl --user enable hyprdynamicmonitors.service

# 4. Restart Hyprland
```

### Monitor Model Discovery

To find your monitor descriptions:
```bash
hyprctl monitors | grep -E "model|description"
```

Example output:
```
Monitor DP-1 (ID 0):
    ...
    make: GIGA-BYTE TECHNOLOGY CO. LTD.
    model: Gigabyte M32U
    description: GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 21411B000071
```

Use the `description` field in `config.toml` for port-agnostic matching.

### Reconfiguring Monitors

**Method 1: TUI (Recommended)**
```bash
hyprdynamicmonitors tui
# Edit profiles in Profile view (Tab key)
# Save changes
```

**Method 2: Manual Config**
```bash
# 1. Edit config
nano ~/.config/hyprdynamicmonitors/config.toml

# 2. Restart service
systemctl --user restart hyprdynamicmonitors
```

## Troubleshooting

### Profile not matching

```bash
# Check monitor descriptions
hyprctl monitors | grep -E "model|description"

# Validate config
hyprdynamicmonitors validate

# Check logs
journalctl --user -u hyprdynamicmonitors -f
```

### Port name changes (DP-1 → DP-2, etc.)

No action needed! Profiles use `description` matching, not port names.

### Monitor disconnect/reconnect issues

```bash
# Check service status
systemctl --user status hyprdynamicmonitors

# View recent logs
journalctl --user -u hyprdynamicmonitors --since "5 minutes ago"
```

### Service fails to start

```bash
# Check dependencies
pacman -Qi hyprdynamicmonitors-bin

# Test manually
hyprdynamicmonitors run --debug

# Check D-Bus
gdbus list --session
```

## Configuration File Structure

```
~/.config/hyprdynamicmonitors/
├── config.toml                 # Profile definitions and settings
└── hyprconfigs/
    └── desktop-dual.conf      # Desktop monitor configuration
```

## Port-Agnostic Matching

Desktop profiles match monitors by **description**, not port names:

- **Description**: `GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 21411B000071`
- **Matches regardless of**: DP-1, DP-2, HDMI-A-1, etc.
- **Benefit**: Swap cables/ports without breaking config

## Power Events

**Disabled** on desktop (not relevant for always-on AC systems).

## Future: Laptop Configuration

Laptop profiles will be added later. Current setup uses existing `monitor.conf.tmpl` as fallback.

**To add laptop support later**:
1. Run `hyprctl monitors` on laptop
2. Create profile with `eDP-1` matching
3. Enable power events in `config.toml`

## Documentation

See: [full configuration examples](https://github.com/fiffeek/hyprdynamicmonitors/tree/main/examples/full)
