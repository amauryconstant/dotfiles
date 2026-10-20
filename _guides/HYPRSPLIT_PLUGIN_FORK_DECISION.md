# hyprsplit Plugin Source: Fork Decision Record

Tracks the decision to source the hyprsplit hyprpm plugin from a fork instead of upstream, and when to revisit it.

## Summary

hyprsplit now comes from the fork `cryeprecision/hyprsplit` instead of upstream
`shezdy/hyprsplit`. The clone lives in `.chezmoiexternal.yaml` (git-repo external) and is loaded
as a **Lua library** via `require("hyprsplit")` (`private_dot_config/hypr/conf/plugins.lua.tmpl`,
`conf/bindings/workspace-management.lua`). No hyprpm build is involved any more.

History: the switch first changed the clone URL in the retired
`run_once_before_008_setup_hyprland_plugins` script and `plugins.conf` (commit `df0bcce`); the
Lua cutover (2026-09-01) made it effective.

## Why

The reason for the fork. Hyprland 0.56.0 moved `Monitor.hpp` from `src/helpers/` to `src/output/`,
breaking upstream's C++ plugin build:

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
`hyprsplit`, so the repository URL was the only change.

## Risk

Single-maintainer forks can go stale or get abandoned faster than the upstream project. This
fork could stop tracking Hyprland releases at any point, leaving us in the same position as
before (broken per-monitor workspace dispatchers) — just one hop removed.

Because the fork is consumed as a Lua library (no compiled plugin, no Hyprland internal headers),
header-lag build breakage no longer applies. The exposure is its **Lua API** stability.

## When to Revisit

The five APIs we call: `config`, `dsp.focus`, `dsp.window.move`, `dsp.workspace.swap_monitors`,
`dsp.grab_rogue_windows`. Periodically check:
- Is `cryeprecision/hyprsplit` still committing after each Hyprland release?
  `curl -s https://api.github.com/repos/cryeprecision/hyprsplit/commits?per_page=5`
- Did a Hyprland upgrade break any of those five calls? (`mise run lint:hypr-lua`, then a
  per-monitor workspace switch on the live session.)
- Has upstream `shezdy/hyprsplit` shipped a Lua API of its own, making the fork unnecessary?

**If the fork stalls**: move to upstream once it supports Lua, or vendor the fork's `init.lua`
into the repo. Pinning Hyprland is only a stopgap and needs `IgnorePkg` in `/etc/pacman.conf`.

## Verified live

`hyprctl plugin list` reports no plugins loaded and `hyprctl -j status` reports
`configProvider: "lua"` (checked 2026-10-20). The Lua cutover is recorded in
`_guides/archive/HYPRLAND_LUA_CUTOVER.md`; the `.conf`/`.lua` pair audit in
`_research/HYPRLAND_LUA_AUDIT.md`.
