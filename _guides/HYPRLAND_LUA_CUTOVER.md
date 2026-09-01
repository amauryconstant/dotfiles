# Hyprland Lua Config Cutover

How to flip the Hyprland entry point from `.conf` to `.lua` when the block lifts, and how to roll
back if it goes wrong.

**See**: `_research/HYPRLAND_LUA_AUDIT.md` for the one-time `.conf`/`.lua` parity audit this
runbook depends on. `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md` for the hyprsplit fork this
cutover also activates.

## Status: unblocked 2026-09-01 — cutover committed, runtime verification pending

All 30 `hyprctl dispatch` call sites are converted and the `.chezmoiignore` block is deleted, so
`~/.config/hypr/hyprland.lua` now deploys. **The session on disk is still the old one** until a
`chezmoi apply` and a log-out/in; the step-6 checklist below has not been run. Do not read this
section as "verified live".

Argument shapes were settled empirically first, in a nested Hyprland running in Lua mode — see
`_research/HYPRLAND_LUA_AUDIT.md` → "Resolved at conversion time". Both of that audit's open
questions are answered there.

The whole Lua tree (`conf/*.lua`, `conf/bindings/*.lua`, `conf.d/*.lua`, `themes/*/hyprland.lua`)
was already deployed; only the **entry point** was held back.

### What the hold was

**The hold reason changed on 2026-09-01.** It used to be Waybar PR #5013 (`fix(hyprland/
workspaces): adapt dispatch commands for Lua IPC protocol`) — merged 2026-05-04, still in no
tagged release, installed waybar is 0.15.0-2. That is now irrelevant, for two reasons:

- The Quickshell bar does workspace clicks correctly in Lua mode (`activate()` branches on
  `Hyprland.usingLua` itself), so nothing we click depends on Waybar any more.
- Since 2026-08-31 the two bars are **mutually exclusive** `conf.d/` drop-ins keyed on
  `features.quickshell_shell`. With the flag on, Waybar does not autostart at all.

**The blocker was internal**: 30 `hyprctl dispatch <legacy string>` call sites across 11 of our
own scripts and configs, every one of which Lua mode breaks. Verified from Hyprland v0.56.2
source — `dispatchRequest` forks on config provider (`src/debug/HyprCtl.cpp:1130`) and splices the
request into `return hl.dispatch(…)`, leaving the legacy dispatcher lookup at `:1149` unreachable,
with no fallback. Five of the sites are `dpms on`, and a dead `dpms on` is a black screen that
does not come back.

The unblock condition was work, not a version comparison: convert the sites. Done 2026-09-01;
the per-site inventory with `hl.dsp.*` replacements is in `_research/HYPRLAND_LUA_AUDIT.md`.

**If the flag is off** (Waybar running), note Waybar is a **degraded** fallback after cutover: it
renders fine — its Hyprland modules read `socket2` events, unaffected — but its workspace clicks
are dead until a release carries #5013. Adequate as a "the QML bar crashed, show me something"
net; not a rollback target. The rollback target is the `.chezmoiignore` block.

| | |
|---|---|
| Installed Hyprland | 0.56.2-1 (the version Omarchy converted for) |
| Installed Waybar | 0.15.0-2 (no 0.16.0 exists; #5013 unreleased) |

## Cutover

1. ~~Delete the `.chezmoiignore` block~~ — done 2026-09-01.
2. `chezmoi diff` — `~/.config/hypr/hyprland.lua` is the one **A**dded path; the rest are the
   converted dispatch sites and the key swap.
3. **`systemctl --user stop hypridle`** before anything else. Five converted sites are `dpms on`,
   and a dead one is a black screen that does not come back; with the daemon stopped nothing can
   blank the display until DPMS is proven by hand in step 6.
4. `chezmoi apply`, then confirm `~/.config/hypr/hyprland.lua` exists. Hyprland prefers it over
   `hyprland.conf`.
5. **Log out and back in.** Not `hyprctl reload` — the entry point itself changes, and a reload
   re-reads the old one. If the session comes up unusable, `Ctrl+Alt+F2` to a TTY and roll back.
6. Verify:
   - **The converted dispatch sites, first** — they are the hold reason. By hand:
     `hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'`, wake, then the `"on"` form; **only
     then** `systemctl --user start hypridle` and let one real idle timeout run. Then a voxtype
     submap entering and resetting (`hyprctl submap`); a `session-restore` round trip across
     two monitors; `window-pop`; the hyprwhenthen float-and-center path; `SUPER+ALT+g`
   - Workspace clicks in the Quickshell bar (or, with the flag off, Waybar's — expected **dead**,
     see Status)
   - hyprsplit per-monitor workspaces: `SUPER+1..0`, `SUPER+SHIFT+1..0`, `SUPER+ALT+s` swap,
     `SUPER+ALT+g` grab
   - `SUPER+ALT+m` actually crosses monitors (audit finding 3)
   - Media keys work on the hyprlock screen (audit finding 4)

Before doing this: resolve the `SUPER+ALT+M` double-bind noted in
`_research/HYPRLAND_LUA_AUDIT.md` (voice's "Toggle meeting transcription" vs
workspace-management's monitor move) — it's identical in both `.conf` and `.lua`, so cutover alone
won't surface it, but it's a real conflict.

## Rollback

`git checkout HEAD -- .chezmoiignore` is **no longer sufficient**: the 30 call sites are Lua-only
now, so restoring the block alone leaves `.conf` mode driving `hl.dsp.*` strings that it rejects.
Revert the conversion too:

```sh
git revert --no-edit <conversion-sha> <key-swap-sha> <ignore-block-sha>
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
