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

## Related

Separately, this repo is deliberately staying on legacy `.conf` mode (not the parallel `.lua`
config) until a Waybar release ships PR #5013 (Lua-IPC workspace clicks) — see the comment above
`.config/hypr/hyprland.lua` in `.chezmoiignore`. That's an independent decision from this one.
