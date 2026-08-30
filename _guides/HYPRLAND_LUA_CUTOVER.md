# Hyprland Lua Config Cutover

How to flip the Hyprland entry point from `.conf` to `.lua` when the block lifts, and how to roll
back if it goes wrong.

**See**: `_research/HYPRLAND_LUA_AUDIT.md` for the one-time `.conf`/`.lua` parity audit this
runbook depends on. `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md` for the hyprsplit fork this
cutover also activates.

## Status: held, waiting on Waybar

The whole Lua tree (`conf/*.lua`, `conf/bindings/*.lua`, `conf.d/*.lua`, `themes/*/hyprland.lua`)
is deployed and sitting on disk. Only the **entry point** `~/.config/hypr/hyprland.lua` is
excluded, by a block in `.chezmoiignore`. With that file absent Hyprland falls back to
`hyprland.conf`, whose legacy `dispatch workspace N` still works.

The blocker is external: Waybar PR #5013 (`fix(hyprland/workspaces): adapt dispatch commands for
Lua IPC protocol`). Waybar workspace clicks go through the legacy text dispatch that Lua mode
removes, so without that PR in a tagged release, clicking a workspace in the bar silently stops
working.

Re-checked **2026-08-30**:

| | |
|---|---|
| PR #5013 merged | 2026-05-04 into master |
| Waybar latest release | **0.15.0** (2026-02-06) — predates the merge |
| Arch `extra` | waybar **0.15.0-2** |
| Installed | waybar 0.15.0-2 |
| Installed Hyprland | 0.56.2-1 (the version Omarchy converted for) |

No 0.16.0 exists. The unblock condition is a version comparison, not a re-investigation: **Waybar
>= 0.16.0** (or any release whose changelog carries #5013).

```sh
curl -s https://api.github.com/repos/Alexays/Waybar/releases/latest | jaq -r .tag_name
pacman -Si waybar | grep Version
```

## Cutover

1. Delete the `.chezmoiignore` block ending in `.config/hypr/hyprland.lua`.
2. `chezmoi diff` — expect exactly one new file, `~/.config/hypr/hyprland.lua`.
3. `chezmoi apply`.
4. Confirm `~/.config/hypr/hyprland.lua` exists. Hyprland prefers it over `hyprland.conf`.
5. **Log out and back in.** Not `hyprctl reload` — the entry point itself changes, and a reload
   re-reads the old one.
6. Verify:
   - Waybar workspace clicks (the whole reason for the hold)
   - hyprsplit per-monitor workspaces: `SUPER+1..0`, `SUPER+SHIFT+1..0`, `SUPER+ALT+s` swap,
     `SUPER+ALT+g` grab
   - `SUPER+ALT+m` actually crosses monitors (audit finding 3)
   - Media keys work on the hyprlock screen (audit finding 4)

Before doing this: resolve the `SUPER+ALT+M` double-bind noted in
`_research/HYPRLAND_LUA_AUDIT.md` (voice's "Toggle meeting transcription" vs
workspace-management's monitor move) — it's identical in both `.conf` and `.lua`, so cutover alone
won't surface it, but it's a real conflict.

## Rollback

```sh
git checkout HEAD -- .chezmoiignore
chezmoi apply
```

Then log out and back in — same reason as step 5.

## The hyprsplit coupling (main cutover risk)

The running session has **shezdy's** hyprsplit v1.0 loaded — the pre-fork C++ hyprpm plugin — not
the `cryeprecision/hyprsplit` fork recorded in `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md`. That
fork switch is committed but inert until this cutover: `autostart.lua` deliberately drops the
`exec-once = hyprpm reload -n` that `autostart.conf` still carries, because under Lua config
hyprsplit loads via `require("hyprsplit")` instead. So flipping the entry point **also** swaps
hyprsplit from the C++ plugin to the Lua library, in the same step. Two changes, one reboot — if
per-monitor workspaces misbehave after cutover, that is the first thing to suspect, and step 6's
hyprsplit checks exist for it. See `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md` for the current
fork state and the full mechanics.

## Validation recipe

`Hyprland --verify-config` exists ("Do not run Hyprland, only print if the config has any
errors"). Since the entry point is chezmoiignore'd, render it to a temp path first:

```sh
TMP=$(mktemp -d)
chezmoi execute-template < private_dot_config/hypr/hyprland.lua.tmpl > "$TMP/hyprland.lua"
Hyprland --verify-config -c "$TMP/hyprland.lua"
```

It resolves the rest of the tree through `package.path`, which the entry point points at the
already-deployed `~/.config/hypr`. So this proves the tree **parses** and every `require` resolves
— it does **not** prove dispatcher arguments are semantically correct (see
`_research/HYPRLAND_LUA_AUDIT.md` finding 3, which no static check would have caught).

Still open, tracked in `_plans/OMARCHY.md`: extend
`run_once_after_007_validate_hyprland_config.sh.tmpl` to run this recipe against whichever entry
point is authoritative.
