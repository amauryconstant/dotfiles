# HyprDynamicMonitors

Desktop monitor profile manager. Two user services (`hyprdynamicmonitors-prepare.service` runs before Hyprland, `hyprdynamicmonitors.service` is the daemon) — both enabled by `run_once_before_008`, not manually. Emits `~/.config/hypr/monitors.conf`, which `hyprland.conf` sources.

- TUI: `hyprdynamicmonitors tui` (edit profiles, Tab to Profile view). Validate: `hyprdynamicmonitors validate`.
- After manual `config.toml` edits: `systemctl --user restart hyprdynamicmonitors`.

## Port-agnostic matching (the key design point)

Profiles match monitors by **description**, never port name — so DP-1↔DP-2 / cable swaps don't break the config. Find descriptions with `hyprctl monitors | grep -E "model|description"` and put the `description` string in `config.toml`.

## This machine

- Profile `desktop_dual`: Gigabyte M32U (4K@144, 1.25x, `0x0`) + BenQ GW2765 (1440p@60, portrait, transform 1).
- Layout files: `config.toml` (profiles) + `hyprconfigs/desktop-dual.conf` (the emitted Hyprland block).
- **Power events disabled** (always-on AC desktop).

## Laptop (deferred)

No laptop profile yet; laptops fall back to `hypr/conf/monitor.conf.tmpl`. To add: capture `hyprctl monitors` on the laptop, create an `eDP-1` profile, enable power events in `config.toml`.

Upstream examples: https://github.com/fiffeek/hyprdynamicmonitors/tree/main/examples/full
