# Hyprland Lua Config: `.conf`/`.lua` Parity Audit

Closed investigation (2026-08-30): every `.conf`/`.lua` pair in the Hyprland config tree, compared
semantically for drift, before the Lua entry point cuts over. All findings below were fixed at the
time of the audit.

**See**: `_guides/HYPRLAND_LUA_CUTOVER.md` for the current hold status and the cutover/rollback
runbook. `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md` for the hyprsplit fork this cutover also
activates.

Two audits live here. The first (2026-08-30) is **config-side**: `.conf`/`.lua` parity. The
second (2026-09-01, at the end of this file) is the **`hyprctl dispatch` script fleet** — 30
call sites that the first audit never scoped, and that a cutover breaks. **All 30 were converted
on 2026-09-01**; see "Conversion" at the end.

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

---

# The `hyprctl dispatch` script fleet (2026-09-01)

Second, separate audit. The 2026-08-30 pass above is **config-side only** — the 21
`.conf`/`.lua` pairs. Our own scripts and app configs call `hyprctl dispatch` with legacy
dispatch strings, and none of that was in scope. `_plans/archive/QUICKSHELL_SHELL.md` Phase 2 carried
the question as *inference, not verified*. It is now verified.

## Verdict: the legacy form **breaks**. Every site must be converted before cutover.

Read from Hyprland `v0.56.2` upstream (the installed version; source is not vendored here).

`hyprctl dispatch` is one registered IPC command, `dispatchRequest`, and it forks on config
provider **before** it ever reaches the dispatcher table:

```
src/debug/HyprCtl.cpp:1126  dispatchRequest()
src/debug/HyprCtl.cpp:1130    if (Config::mgr()->type() == Config::CONFIG_LUA) {
src/debug/HyprCtl.cpp:1132      std::string evalStr = std::format("return hl.dispatch({})", in);
src/debug/HyprCtl.cpp:1134      auto ret = luaMgr->eval(evalStr).value_or("ok");
                                 …returns here…
src/debug/HyprCtl.cpp:1149    const auto DISPATCHER = g_pKeybindManager->m_dispatchers.find(DISPATCHSTR);
```

Line 1149 — the legacy lookup in `m_dispatchers` — is unreachable in Lua mode. The text after
`dispatch ` is spliced into Lua source verbatim, so `dispatch workspace 2` becomes
`return hl.dispatch(workspace 2)`, a syntax error. There is no fallback path: the `if` returns
unconditionally.

`hl.dispatch` will not take a legacy string either — it requires a dispatcher userdata built by
`hl.dsp.*`:

```
src/config/lua/bindings/LuaBindingsToplevel.cpp:352  hlDispatch()
                                              :354    "hl.dispatch: expected a dispatcher (e.g. hl.dsp.window.close())"
src/config/lua/bindings/LuaBindingsDispatchers.cpp:1343  registerDispatcherBindings() — the hl.dsp table
```

**`hyprctl --batch` is the same code path.** `dispatchBatch` (`HyprCtl.cpp:1309`) splits on `;`
and feeds each fragment back through `g_pHyprCtl->getReply()`, i.e. through `dispatchRequest`
again. A batch of six dispatches is six broken calls, not one.

**Failure is loud, but our call sites silence it.** `CConfigManager::eval`
(`src/config/lua/ConfigManager.cpp:880`) returns `error: …`, `dispatchRequest` appends a hint,
and `hyprctl` maps a reply starting with `error:` to **exit 7** (`hyprctl/src/main.cpp:277`).
That exit code is worth nothing where we wrote `2>/dev/null || true`, `|| exit 0`, or
`>/dev/null 2>&1` — which is most of the fleet — and hypridle ignores its command's status
entirely.

## Replacement form

Quoting is a shell concern only; `hyprctl` joins `argv` with spaces (`main.cpp:470`) and the
compositor sees the joined text.

```sh
hyprctl dispatch 'hl.dsp.focus({ workspace = "2" })'
```

The `hl.dsp.*` argument shapes are **not** in `/usr/share/hypr/stubs/hl.meta.lua` — it types
every dispatcher as `fun(...): HL.Dispatcher`. They come from
`src/config/lua/bindings/LuaBindingsDispatchers.cpp`, one `hl*` factory per entry.

## Inventory — 30 call sites across 11 files

Larger than the ~12 the plan estimated: it missed the shared hypridle template and the
six-dispatch batch in `window-pop`. A 30th was found on 2026-09-01 — `PowerMenu.qml`, which
postdates this table.

| File:line | Legacy call | Replacement |
|---|---|---|
| `.chezmoitemplates/hypridle_general:11` | `dpms on` | `hl.dsp.dpms({ action = "on" })` |
| `hypr/hypridle.conf.tmpl:28,29` | `dpms off` / `dpms on` | `hl.dsp.dpms({ action = "off"/"on" })` |
| `hypr/hypridle-nolock.conf.tmpl:20,21` | `dpms off` / `dpms on` | idem |
| `hyprwhenthen/scripts/executable_float-and-center.sh:3` | `togglefloating address:$A` | `hl.dsp.window.float({ window = "address:$A" })` |
| `…:4` | `resizewindowpixel exact 50% 50%,address:$A` | `hl.dsp.window.resize({ x =, y =, window = })` — ⚠ `x`/`y` are numbers, no percent form; the 50% must be computed |
| `…:5` | `focuswindow address:$A` | `hl.dsp.focus({ window = "address:$A" })` |
| `…:6` | `centerwindow` | `hl.dsp.window.center({})` |
| `voxtype/config.toml.tmpl:67,68,69` | `submap voxtype_recording` / `voxtype_suppress` / `reset` | `hl.dsp.submap("…")` |
| `wlogout/layout:9` | `exit` | `hl.dsp.exit()` |
| `quickshell/dotfiles/power/PowerMenu.qml:47` | `exit` | `hl.dsp.exit()` — **added 2026-09-01**, postdates the original count. Deploys whenever `features.quickshell_shell.enabled` |
| `desktop/executable_launch-or-focus:31` | `focuswindow address:$W` | `hl.dsp.focus({ window = … })` |
| `desktop/executable_recover-workspaces:10` | `split:grabroguewindows` | `require("hyprsplit").dsp.grab_rogue_windows()` — ⚠ see open question |
| `desktop/executable_session-restore:182,187,192,200` | `exec "[monitor M; workspace N silent] cmd"` | `hl.dsp.exec_cmd(cmd, { monitor = "M", workspace = "N silent" })` — rules table is keyed by window-rule effect name (`LuaBindingsInternal.cpp:buildRuleFromTable`) |
| `…:316,403` | `movetoworkspacesilent "N,address:$A"` | `hl.dsp.window.move({ workspace = "N", follow = false, window = "address:$A" })` — `silent` is `follow = false` |
| `…:335,406` | `moveworkspacetomonitor "N M"` | `hl.dsp.workspace.move({ workspace = "N", monitor = "M" })` |
| `desktop/executable_window-pop:21-26` (one `--batch`) | `togglefloating` · `resizeactive exact W H` · `centerwindow` · `pin` · `alterzorder top` · `tagwindow +pop` | `hl.dsp.window.float` · `.resize({ x = W, y = H })` · `.center({})` · `.pin({})` · `.alter_zorder({ mode = "top" })` · `.tag({ tag = "+pop" })` |

Dangerous two, unchanged from the plan's assessment and now confirmed to be real: **`dpms on`**
(five of the sites; a dead one is a black screen that does not come back) and the **voxtype
submaps** (a stuck `voxtype_suppress` submap swallows the keyboard).

## Resolved at conversion time (2026-09-01)

Both settled empirically against a **nested Hyprland in Lua mode** before any site was committed
— a minimal entry point (`hl.config({})` plus the real `package.path`) run as
`Hyprland -c <tmp>/hyprland.lua`, which nests as a Wayland client and reports
`configProvider: "lua"` on `hyprctl -j status`. Legacy `dispatch centerwindow` there returns
`error: … expected a dispatcher` and exit 7, confirming the fork; every `hl.dsp.*` form below
returned `ok`.

- **`workspace = "N silent"` as a rule-table value — accepted verbatim.** Not just "no error":
  `hl.dsp.exec_cmd([[ghostty]], { monitor = "WAYLAND-1", workspace = "7 silent" })` put the
  window on workspace 7 while the active workspace stayed unchanged. The suffix needs no
  separate key.
- **`require("hyprsplit")` inside a dispatch eval string — resolves.** It runs in the config's
  `lua_State`, so the entry point's `package.path` applies. Proved by negative control: the same
  call with a typo'd module name returns `module 'hyprsplit_NOPE' not found`, so the working call
  is genuinely resolving rather than silently no-oping.

Also verified live, since none of it is checkable statically (the stub types every dispatcher as
`fun(...): HL.Dispatcher`):

- `hl.dsp.window.resize({ x = N, y = N })` is **exact**, not a delta — a window came out at
  precisely the requested size.
- `hyprctl --batch` works with Lua fragments: all six of `window-pop`'s applied in one call.
  No replacement string contains a `;`, so the batch separator stays unambiguous.
- A Lua **long-bracket string** `[[...]]` carries a command containing single quotes with no
  escaping — which is what `session-restore` now uses for `exec_cmd`.
- `hl.dsp.window.float` is a **toggle** (it replaces `togglefloating`), unchanged from the
  legacy behaviour: firing it at an already-floating window un-floats it.

## Conversion (2026-09-01)

All 30 sites converted to `hl.dsp.*`. Three did not survive as straight substitutions:

- **`session-restore`** — the four `exec` sites collapsed into one `dispatch_exec()` helper.
  `$rules` is now a Lua **table literal** built where the `[...]` string used to be built, and
  the command goes through `[[ ]]` so a quote inside it needs no escaping.
- **`float-and-center.sh`** — `resizewindowpixel exact 50% 50%` has no Lua equivalent
  (`hl.dsp.window.resize` takes numbers), so the 50% is computed from the window's monitor.
- **`window-pop`** — each `--batch` fragment got its own `hl.dsp.*` call.

**Two pre-existing defects surfaced while converting, both about monitor geometry:**

1. `window-pop` read its monitor size as `hyprctl activeworkspace -j | jq -r '.monitor.width'`.
   `.monitor` there is a **name string**, so that yielded empty, `$((… * 30 / 100))` evaluated to
   0, and the "30% size" was a `resizeactive exact 0 0`. It had never worked. Dimensions only
   exist on `hyprctl monitors -j`.
2. `hyprctl monitors` reports `.width`/`.height` in **physical** pixels, while window geometry is
   **logical**. Dividing by `.scale` is mandatory: on the nested monitor (944x1004 at scale 2) a
   "half size" computed from the physical width came out as the *entire* logical monitor. Verified
   after the fix: exactly 236x251 of a 472x502 logical monitor. The laptop runs scale 1 so it
   would have hidden this; the desktop profile's 3840x2160 at scale 1.25 would not.

**One site did not become a dispatch string at all.** voxtype's
`output.{pre_recording,pre_output,post_output}_command` hooks are undocumented on whether they run
through a shell, and the Lua call survives `sh -c` only if quoted and naive argv splitting only if
*not* quoted. They now call `desktop/hypr-submap <name>`, a wrapper that keeps the hook a plain
whitespace-separated command — so neither reading can break it. The path is written absolute via
`{{ .chezmoi.homeDir }}` for the same reason (`~` is also shell-only). Side effect: `voxtype check`
compares against its own hardcoded `hyprctl dispatch submap <name>` and now reports
*"configured (but not for Hyprland)"*. Cosmetic.

**Confirmed on the real session after the reboot** (full table in
`_guides/HYPRLAND_LUA_CUTOVER.md`): DPMS goes off *and back on* (`dpmsStatus` true → false → true,
and both `misc.*_enables_dpms` options are false here, so `dpms on` is genuinely the only way
back); a production `session-restore` fired all four `exec_cmd` rules-table dispatches and got
4/4 windows back; `hyprctl plugin list` reports no plugins, so hyprsplit is the Lua library;
`window-pop` lands an exact 30%.

**Still unverified**, for want of hardware: anything **multi-monitor** — `hl.dsp.workspace.move`'s
monitor argument and `SUPER+ALT+m` were exercised only against a nested headless output added with
`hyprctl output create headless`. Re-check on the desktop profile.

One more instance of the "`ok` proves nothing" trap, found while cleaning up a test window:
`hl.dsp.window.close({ window = "address:0x…" })` returns `ok` and does **nothing**;
`hl.dsp.window.close({})` closes the active window. Not one of our 30 sites, but the same shape as
a defect that would have shipped silently.
