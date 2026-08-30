# Hyprland Lua Config: `.conf`/`.lua` Parity Audit

Closed investigation (2026-08-30): every `.conf`/`.lua` pair in the Hyprland config tree, compared
semantically for drift, before the Lua entry point cuts over. All findings below were fixed at the
time of the audit.

**See**: `_guides/HYPRLAND_LUA_CUTOVER.md` for the current hold status and the cutover/rollback
runbook. `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md` for the hyprsplit fork this cutover also
activates.

## Audit results

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
not `.conf`/`.lua` drift, but it is a real conflict to resolve before or during cutover — tracked
in `_plans/OMARCHY.md`.

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
errors". It resolves the rest of the tree through `package.path`, proving the tree **parses** and
every `require` resolves — it does **not** prove dispatcher arguments are semantically correct. The
runnable recipe lives in `_guides/HYPRLAND_LUA_CUTOVER.md`, which is where it gets used.
