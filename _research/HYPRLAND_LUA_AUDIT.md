# Hyprland Lua Config: `.conf`/`.lua` Parity Audit

Closed investigation (2026-08-30): every `.conf`/`.lua` pair in the Hyprland config tree, compared
semantically for drift, before the Lua entry point cuts over. All findings below were fixed at the
time of the audit.

**See**: `_guides/HYPRLAND_LUA_CUTOVER.md` for the current hold status and the cutover/rollback
runbook. `_guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md` for the hyprsplit fork this cutover also
activates.

Two audits live here. The first (2026-08-30) is **config-side**: `.conf`/`.lua` parity. The
second (2026-09-01, at the end of this file) is the **`hyprctl dispatch` script fleet** — 29
call sites that the first audit never scoped, and that a cutover breaks.

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
dispatch strings, and none of that was in scope. `_plans/QUICKSHELL_SHELL.md` Phase 2 carried
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

## Inventory — 29 call sites across 10 files

Larger than the ~12 the plan estimated: it missed the shared hypridle template and the
six-dispatch batch in `window-pop`. Conversion is deliberately **not** done here.

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
| `desktop/executable_launch-or-focus:31` | `focuswindow address:$W` | `hl.dsp.focus({ window = … })` |
| `desktop/executable_recover-workspaces:10` | `split:grabroguewindows` | `require("hyprsplit").dsp.grab_rogue_windows()` — ⚠ see open question |
| `desktop/executable_session-restore:182,187,192,200` | `exec "[monitor M; workspace N silent] cmd"` | `hl.dsp.exec_cmd(cmd, { monitor = "M", workspace = "N silent" })` — rules table is keyed by window-rule effect name (`LuaBindingsInternal.cpp:buildRuleFromTable`) |
| `…:316,403` | `movetoworkspacesilent "N,address:$A"` | `hl.dsp.window.move({ workspace = "N", follow = false, window = "address:$A" })` — `silent` is `follow = false` |
| `…:335,406` | `moveworkspacetomonitor "N M"` | `hl.dsp.workspace.move({ workspace = "N", monitor = "M" })` |
| `desktop/executable_window-pop:21-26` (one `--batch`) | `togglefloating` · `resizeactive exact W H` · `centerwindow` · `pin` · `alterzorder top` · `tagwindow +pop` | `hl.dsp.window.float` · `.resize({ x = W, y = H })` · `.center({})` · `.pin({})` · `.alter_zorder({ mode = "top" })` · `.tag({ tag = "+pop" })` |

Dangerous two, unchanged from the plan's assessment and now confirmed to be real: **`dpms on`**
(five of the sites; a dead one is a black screen that does not come back) and the **voxtype
submaps** (a stuck `voxtype_suppress` submap swallows the keyboard).

## Open at conversion time

- **`split:grabroguewindows` scope.** Under Lua, hyprsplit is a Lua library
  (`~/.config/hypr/hyprsplit/init.lua:303` `hyprsplit.dsp.grab_rogue_windows`), and our config
  reaches it through a **local** `require("hyprsplit")` per module — not a global. The
  `hyprctl` eval runs in the config's `lua_State`, so `require("hyprsplit")` inside the
  dispatch string should resolve via the `package.path` the entry point sets, but this is the
  one line in the table not settled from source. Check it live right after cutover.
- **`workspace N silent` as a rule-table value.** The legacy rule string is passed through as
  `{ workspace = "N silent" }`; whether the Lua side accepts the `silent` suffix or wants a
  separate key is unverified.
