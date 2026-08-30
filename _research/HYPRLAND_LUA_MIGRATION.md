# Hyprland Lua Config: Migration Status and Cutover Runbook

Tracks why the Lua entry point is held back, what the `.conf`/`.lua` audit found, and the exact
steps to flip the config over when the block lifts.

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

## Audit results (2026-08-30)

All 21 `.conf`/`.lua` pairs compared semantically — 9 in `conf/`, 11 in `conf/bindings/`, plus the
`hyprland.{conf,lua}.tmpl` entry point. 17 at parity. Four findings:

1. **`voice.lua` was not a template.** `voice.conf.tmpl` gates the two Parakeet bindings
   (`SUPER+ALT+T` streaming, `SUPER+CTRL+T` push-to-talk) behind
   `{{ if ne .chassisType "laptop" }}` because the laptop is RAM-constrained and Cohere-only.
   `voice.lua` had no `.tmpl` suffix, so it bound them unconditionally. Resolution: renamed to
   `voice.lua.tmpl` with the gate added. Same bug class as commit `0ab31dd` (missing `.tmpl` on
   `environment.lua`) — a `.lua` twin of a `.conf.tmpl` must carry the suffix too.

2. **Rose-pine border colors were malformed.** `themes/rose-pine-dawn/` and
   `themes/rose-pine-moon/` wrote **10** hex digits — `0xffc4a7e7ee` = `0xff` + `c4a7e7` + `ee` —
   in *both* `hyprland.conf` and `hyprland.lua`. Hyprland silently keeps only the last 8 and drops
   the leading `ff`. Verified live: `hyprctl getoption general:col.active_border` returned
   `907aa9ee`. The other six themes already used `rgba(rrggbbaa)`. Resolution: converted to
   `rgba(...)`. See `.claude/rules/hyprland-lua.md` → Color format.

3. **`SUPER+ALT+m` did not do what its description said.** Both sources read "Move to other
   monitor" but neither crossed a monitor: `.conf` had `split:workspace, +1, movecurrentwindow`
   and `.lua` had `hs.dsp.window.move({ workspace = "+1" })` — both move within the current
   monitor's workspace range. Resolution: `movewindow, mon:+1` (.conf) /
   `hl.dsp.window.move({ monitor = "+1" })` (.lua).

4. **Media keys were dead on the lock screen.** `media-keys.lua` used
   `{ locked = true, repeating = true }`; `.conf` used plain `bindd`, so volume and brightness did
   nothing under hyprlock. Resolution: `.conf` switched to `bindeld` (volume/brightness — locked +
   repeat) and `bindld` (playback — locked only; repeat is meaningless).

**Open, not part of the four**: `SUPER+ALT+M` is bound twice — `conf/bindings/voice.{conf,lua}`
binds it to "Toggle meeting transcription", and `conf/bindings/workspace-management.{conf,lua}`
binds it to the monitor move from finding 3. Both sets carry the collision identically, so it is
not `.conf`/`.lua` drift, but it is a real conflict to resolve before or during cutover.

## Verified prerequisites

**hyprsplit is available as a Lua library.**
`run_once_before_008_setup_hyprland_plugins.sh.tmpl` clones `cryeprecision/hyprsplit` to
`~/.config/hypr/hyprsplit`, and `init.lua` is present there. All five APIs our config calls exist
in it:

| Call site | API |
|---|---|
| `conf/plugins.lua` | `hyprsplit.config` |
| `conf/bindings/workspace-management.lua` | `hyprsplit.dsp.focus` |
| " | `hyprsplit.dsp.window.move` |
| " | `hyprsplit.dsp.workspace.swap_monitors` |
| " | `hyprsplit.dsp.grab_rogue_windows` |

**Every `hl.*` call maps to the shipped 0.56.2 stub** `/usr/share/hypr/stubs/hl.meta.lua`.
`description` and `release` are both valid `HL.BindOptions` fields. Caveat: the stub types every
dispatcher as `fun(...): HL.Dispatcher` (untyped varargs), so LuaLS validates *that a dispatcher
exists*, never its **arguments**. Finding 3 is exactly the class of bug static checking cannot
catch.

**`Hyprland --verify-config` exists** — "Do not run Hyprland, only print if the config has any
errors". Since the entry point is chezmoiignore'd, render it to a temp path first:

```sh
TMP=$(mktemp -d)
chezmoi execute-template < private_dot_config/hypr/hyprland.lua.tmpl > "$TMP/hyprland.lua"
Hyprland --verify-config -c "$TMP/hyprland.lua"
```

It resolves the rest of the tree through `package.path`, which the entry point points at the
already-deployed `~/.config/hypr`. So this proves the tree **parses** and every `require` resolves
— it does **not** prove dispatcher arguments are semantically correct.

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
   - `SUPER+ALT+m` actually crosses monitors (finding 3)
   - Media keys work on the hyprlock screen (finding 4)

## Rollback

```sh
git checkout HEAD -- .chezmoiignore
chezmoi apply
```

Then log out and back in — same reason as step 5.

## The hyprsplit coupling (main cutover risk)

The running session has **shezdy's** hyprsplit v1.0 loaded — the pre-fork C++ hyprpm plugin
(`hyprctl plugin list` → `Plugin hyprsplit by shezdy … Version: 1.0`) — and
`~/.local/share/hyprpm/` is **empty**. So the fork switch recorded in
`_research/HYPRSPLIT_PLUGIN_FORK_DECISION.md` (commit `df0bcce`) has not taken effect in the live
session.

It takes effect at this cutover. `autostart.lua` deliberately drops the
`exec-once = hyprpm reload -n` that `autostart.conf` still carries, because under Lua config
hyprsplit loads via `require("hyprsplit")`. So flipping the entry point **also** swaps hyprsplit
from the C++ plugin to the Lua library, in the same step. Two changes, one reboot — if per-monitor
workspaces misbehave after cutover, that is the first thing to suspect, and step 6's hyprsplit
checks exist for it.
