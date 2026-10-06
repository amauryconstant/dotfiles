# Hyprland Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/hypr/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Hyprland compositor configuration
- **Main entry**: `hyprland.lua` (`require`s the `conf/` modules; `hyprland.conf` remains on disk as the fallback/rollback path)
- **Active format**: **`.lua`**, as of the 2026-09-01 cutover — the `.chezmoiignore` block holding back `~/.config/hypr/hyprland.lua` is gone, and Hyprland prefers that entry point over `hyprland.conf`. The `.conf` set stays deployed as the rollback target until the Lua path is confirmed across a reboot. The hold was never a Waybar release in the end (PR #5013 is still unreleased and no longer matters): it was 30 of our own `hyprctl dispatch <legacy string>` sites, all converted to `hl.dsp.*`. See `.claude/rules/hyprland-lua.md` for syntax, **`_guides/HYPRLAND_LUA_CUTOVER.md` for the cutover runbook** (steps, rollback), `_research/HYPRLAND_LUA_AUDIT.md` for the parity audit and the dispatch inventory.
- 🚨 **No `hyprctl dispatch <legacy string>` anywhere.** Lua mode splices the request verbatim into `return hl.dispatch(...)`, so a legacy string is a hard error (exit 7) with no fallback — and almost every call site in this tree swallows that status. New code writes `hyprctl dispatch 'hl.dsp.…'`.
- **Cutover side effect**: flipping the entry point also swaps hyprsplit from the hyprpm **C++ plugin** to the **Lua library** (`require("hyprsplit")`), because `autostart.lua` deliberately drops the `exec-once = hyprpm reload -n` that `autostart.conf` carries. Two changes, one reboot.
- **Reload**: `Super+Shift+R` or `hyprctl reload`

## Modular Structure

`hyprland.conf` also pulls `conf.d/*.conf` (drop-ins), `monitors.conf` (HyprDynamicMonitors output), and `~/.config/themes/current/hyprland.conf` (theme borders).

**The polkit agent lives in `conf.d/` too, on its own flag.** A session may have exactly one agent, and the Quickshell shell ships one (`quickshell/dotfiles/polkit/PolkitDialog.qml`), so `conf.d/polkit-gnome.{lua,conf}` deploys only when `features.quickshell_polkit` is **off**. Its own flag rather than `quickshell_shell`, for the same reason `quickshell_notifications` is separate: running the bar and displacing a session-exclusive D-Bus agent are separate decisions. That line used to sit unconditionally in `conf/autostart.*`, which **both** branches load.

**Status bar lives in `conf.d/`, not in `conf/`.** `conf.d/waybar.{lua,conf}` and `conf.d/quickshell.{lua,conf}` each carry their own autostart **and** `SUPER+B`; `.chezmoiignore` deploys exactly one pair, keyed on `features.quickshell_shell` — the Quickshell bar floats and reserves 56px, which Waybar's full-bleed bar cannot stack with. Shell docs: `private_dot_config/quickshell/CLAUDE.md`.

**Base config files** (`conf/`, each `.conf` shadowed by an inactive `.lua`):

| File | Purpose | Template? |
|------|---------|-----------|
| `monitor.conf.tmpl` | Display settings (resolution, scaling, position) | ✅ Yes |
| `plugins.conf` | hyprsplit / plugin config | ❌ No |
| `environment.conf` | Empty pointer — session env lives in `uwsm/env.tmpl` (reaches systemd units too) | ❌ No |
| `input.conf` | Keyboard, mouse, touchpad | ❌ No |
| `general.conf` | Layout, gaps, borders, colors, **`misc`** | ❌ No |
| `decoration.conf` | Visual effects (blur, shadows, rounding) | ❌ No |
| `animations.conf` | Animation curves, timing | ❌ No |
| `windowrules.conf` | Per-app window behavior | ❌ No |
| `autostart.conf` | Startup apps (nextcloud, awww, keyring). **No status bar and no polkit agent** — both are branch decisions, see `conf.d/` below | ❌ No |

`helpers.lua`, `require_all.lua` are Lua-layer infrastructure (inactive).

🚨 **`general` carries the tree's only `misc` block, and it holds one setting:
`allow_session_lock_restore = true`.** An `ext-session-lock` outlives its client, so a locker that
dies leaves the compositor's failsafe up and, by default, Hyprland *refuses* a replacement client —
the session is then unauthenticatable without a TTY. With the option on, a fresh locker re-acquires
the existing lock. Two consequences, both already handled: `desktop/session-locked` is how that
stranded state is detected, and `desktop/immediate-lock` had to move from `pidof` to a `flock`,
because the compositor now accepts the second locker a lost race would spawn.

**Keybinding files** (`conf/bindings/`, sourced by `hyprland.conf`):

| File | Purpose | Template? |
|------|---------|-----------|
| `applications.conf.tmpl` | App launchers (terminal, browser, editor) | ✅ Yes |
| `window-management.conf` | Window operations (close, float, fullscreen) | ❌ No |
| `focus-navigation.conf` | Focus + move (arrows, vim keys) | ❌ No |
| `workspace-management.conf` | Switch + move windows across workspaces | ❌ No |
| `window-resizing.conf` | Resize + mouse bindings | ❌ No |
| `media-keys.conf` | Volume, brightness, playback | ❌ No |
| `screenshots.conf` | Screenshot tools (Satty) | ❌ No |
| `voice.conf.tmpl` | Voice dictation (Voxtype; Parakeet bindings desktop-only) | ✅ Yes |
| `desktop-utilities.conf` | Utilities (audio, gaps, nightlight, idle). **`SUPER+B` is not here** — see `conf.d/` below | ❌ No |
| `theme-session.conf` | Theme switching, dark mode | ❌ No |
| `system-control.conf.tmpl` | Lock, power, help, menu (the wlogout `SUPER+SHIFT+Q` is gated on `features.quickshell_shell`) | ✅ Yes |

Bindings use `bindd` (self-documenting descriptions). Modifier convention: SUPER (primary), SUPER+SHIFT (move/variant), SUPER+CTRL (system).

**User extras** (`~/.config/dotfiles/extra-bindings.conf`):

**User extra bindings**: `~/.config/dotfiles/extra-bindings.conf`
- Sourced last — personal bindings without modifying core config
- Chezmoi-managed (always present, prevents Hyprland parse error)
- Edit via: `dotfiles-bindings-edit` (auto-reloads on exit)
- See: `dotfiles/CLAUDE.md` for full documentation

## Template Decisions

Templated files: `hyprland.conf.tmpl`, `hyprlock.conf.tmpl`, `hypridle.conf.tmpl`, `hypridle-nolock.conf.tmpl` (both pull timeouts from `globals.idle` and share `.chezmoitemplates/hypridle_general`), `conf/monitor.conf.tmpl` (laptop vs desktop displays), `conf/bindings/applications.conf.tmpl` (`{{ .globals.applications.terminal }}`; the Wofi `SUPER+D` gated on `features.quickshell_shell`), `conf/bindings/voice.conf.tmpl` (Parakeet bindings gated `{{ if ne .chassisType "laptop" }}`), `conf/bindings/system-control.conf.tmpl` (the wlogout `SUPER+SHIFT+Q`, same gate).

Every one has a `.lua.tmpl` twin: `hyprland.lua.tmpl`, `conf/monitor.lua.tmpl`, `conf/bindings/applications.lua.tmpl`, `conf/bindings/voice.lua.tmpl`, `conf/bindings/system-control.lua.tmpl`. **A `.lua` twin of a `.conf.tmpl` must carry the `.tmpl` suffix too** — dropping it silently un-gates the template's conditionals. This has bitten twice: `environment.lua` (commit `0ab31dd`) and `voice.lua` (the chassis gate on the two Parakeet bindings). Everything else is static — Hyprland syntax rarely needs dynamic values, so prefer editing the static `.conf` directly.

## Theme System Integration

**Static theme files**: Unlike GTK apps (Waybar, Wofi, Wlogout), Hyprland uses static theme files per theme variant.

**Border colors** (`~/.config/themes/{theme}/hyprland.conf`):
```conf
# Example: Rose Pine Moon
$activeBorder = rgba(c4a7e7ee)    # iris (accent-border semantic)
$inactiveBorder = rgba(6e6a86aa)  # muted (fg-muted semantic)
```

**Semantic mapping** (Phase 2):
- Active borders use `accent-border` semantic (violet/iris/yellow per theme)
- Inactive borders use `fg-muted` semantic
- **Note**: Hyprland syntax doesn't support CSS `@variable` imports - uses shell-style `$variables` with hardcoded hex values

**Color format**: `rgba(hexee)` where `hex` = 6-digit color, `ee` = alpha channel (no # prefix)

**Border migration** (Phase 2): Borders migrated from `accent-primary` to dedicated `accent-border` for semantic clarity

## Reload

`hyprctl reload`. ⚠️ `Super+Shift+R` is documented as the reload key in `hyprland.conf.tmpl` and
`dotfiles/extra-bindings.conf`, but **no such binding exists** anywhere in the repo — verified with
`grep -rE 'bind[a-z]* *= *[^,]*, *R,' private_dot_config/`. Either add it or drop the claim. `post_install` script `run_once_after_008_validate_hyprland_config` validates config after apply. Live-test a value without reloading via `hyprctl keyword general:gaps_in 5`.

## Integration Points

- **Theme borders**: `~/.config/themes/current/hyprland.conf` (sourced)
- **Desktop scripts**: `~/.local/lib/scripts/desktop/`
- **Menu system**: `~/.local/lib/scripts/user-interface/` (Super+Space)
- **Monitor automation**: `monitors.conf` from `hyprdynamicmonitors/` (see its CLAUDE.md)
