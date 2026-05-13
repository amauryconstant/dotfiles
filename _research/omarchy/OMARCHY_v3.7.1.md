# Omarchy v3.7.1 — Release Research

**Date researched**: 2026-05-13
**Previous version**: v3.7.0
**Commits**: 2
**Source**: GitHub release notes

---

## Summary

Single-fix patch release targeting Dell XPS Panther Lake systems. A stale `xe.enable_panel_replay=0` kernel cmdline parameter, previously introduced for Intel Xe GPU panel replay workarounds on those machines, was left behind in `/etc/default/limine` after no longer being needed. This migration removes it and re-runs `limine-update` to apply the clean config.

## Breaking Changes

*None*

## Bug Fixes

- **Remove stale `xe.enable_panel_replay=0` kernel cmdline**: A migration script (`migrations/1777909712.sh`) removes any `KERNEL_CMDLINE` line containing `xe.enable_panel_replay` from `/etc/default/limine` on affected hardware, then calls `sudo limine-update`. The fix is conditional: it only runs on systems where `omarchy-hw-match "XPS"` and `omarchy-hw-intel-ptl` both return true (Dell XPS with Intel Panther Lake CPU). Omarchy path: `migrations/1777909712.sh`.
