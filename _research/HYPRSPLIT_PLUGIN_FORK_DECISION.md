# hyprsplit Plugin Source: Fork Decision Record

Tracks the decision to source the hyprsplit hyprpm plugin from a fork instead of upstream, and when to revisit it.

## Summary

Switched `private_dot_config/hypr/conf/plugins.conf` and the hyprsplit clone URL in
`.chezmoiscripts/run_once_before_008_setup_hyprland_plugins.sh.tmpl` from upstream
`shezdy/hyprsplit` to the fork `cryeprecision/hyprsplit`.

## Why

Hyprland 0.56.0 moved `Monitor.hpp` from `src/helpers/` to `src/output/`, breaking upstream's
C++ plugin build:

```
fatal error: hyprland/src/helpers/Monitor.hpp: No such file or directory
```

Confirmed via `shezdy/hyprsplit` issue #87 (open, unfixed as of 2026-07-21). Upstream has a long
history of lagging behind Hyprland internal refactors — 15+ closed issues over time, each a
build failure after a Hyprland header/API move (#7, #17, #18, #24, #28, #37, #41, #45, #51, #62,
#65, #66, #67, #68, #79).

`cryeprecision/hyprsplit` (a fork) had already pushed a fixup commit (`6870872c`, "chase
Hyprland") for this exact header move the day before we hit the bug, plus several other include
updates tracking Hyprland's latest internal refactor (`state/MonitorState.hpp`,
`WorkspacePlacementController.hpp`, etc.). Its `hyprpm.toml` manifest still names the plugin
`hyprsplit`, so no `plugins.conf` config change was needed — only the repository URL.

## Risk

Single-maintainer forks can go stale or get abandoned faster than the upstream project. This
fork could stop tracking Hyprland releases at any point, leaving us in the same position as
before (stuck plugin, broken per-monitor workspace dispatchers) — just one hop removed.

## When to Revisit

Periodically check:
- Is `cryeprecision/hyprsplit` still committing shortly after each Hyprland release?
  `curl -s https://api.github.com/repos/cryeprecision/hyprsplit/commits?per_page=5`
- Has upstream `shezdy/hyprsplit` fixed its header-lag pattern (faster maintenance, CI tracking
  Hyprland git)?
- Any new `hyprpm update` build failures pointing back to this same class of problem (missing
  Hyprland internal header).

**If the fork stalls**: switch back to upstream once it's fixed, or fall back to pinning
Hyprland to the last known-good release as a stopgap (see `package-manager pin` —
`private_dot_local/lib/scripts/system/package-manager/CLAUDE.md`; note the Phase-2 `-Syu` in
`cmd-update.sh` does not currently respect version pins, so a real Hyprland pin would need
`IgnorePkg` in `/etc/pacman.conf` too, not packages.yaml alone).

## The fork switch has not taken effect yet

The fork is consumed as a **Lua library**, not (only) as a compiled hyprpm plugin.
`run_once_before_008_setup_hyprland_plugins.sh.tmpl` clones `cryeprecision/hyprsplit` to
`~/.config/hypr/hyprsplit`, and its `init.lua` is what `conf/plugins.lua` and
`conf/bindings/workspace-management.lua` reach via `require("hyprsplit")`. That path sidesteps the
C++ build entirely — no Hyprland internal headers, so no header-lag breakage.

But the live session is still on the old plugin (checked 2026-08-30):

```
$ hyprctl plugin list
Plugin hyprsplit by shezdy:  Version: 1.0  Description: split monitor workspaces
$ ls -A ~/.local/share/hyprpm/     # empty
```

That's **shezdy's** pre-fork C++ build, loaded because `autostart.conf` still runs
`exec-once = hyprpm reload -n`. So the URL change in commit `df0bcce` is committed but inert.

It takes effect at the **Lua cutover**: `autostart.lua` deliberately drops that
`hyprpm reload -n`, so once `hyprland.lua` becomes the entry point the C++ plugin stops loading and
hyprsplit comes from the fork's Lua library instead. Two changes ride one reboot — see
`_research/HYPRLAND_LUA_MIGRATION.md` → "The hyprsplit coupling".

Practical consequence: the fork's *build* health (the "When to Revisit" checks above) matters less
after cutover than its *Lua API* stability. The five APIs we call are `config`, `dsp.focus`,
`dsp.window.move`, `dsp.workspace.swap_monitors`, `dsp.grab_rogue_windows`.

## Related

Separately, this repo is deliberately staying on legacy `.conf` mode (not the parallel `.lua`
config) until a Waybar release ships PR #5013 (Lua-IPC workspace clicks) — see the comment above
`.config/hypr/hyprland.lua` in `.chezmoiignore`. That's an independent decision from this one.
