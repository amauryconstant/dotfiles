# Omarchy v3.8.2 — Release Research

**Date researched**: 2026-06-08
**Previous version**: v3.8.1
**Commits**: 2
**Source**: GitHub release notes

---

## Summary

A small patch release focused on three fixes: log-upload reliability, compatibility with Hyprland 0.55, and a boot-channel selection bug. No new features or package changes are documented.

## Breaking Changes

*None*

## Bug Fixes

- **Log upload container**: Fixed log uploads by switching to an Omarchy-owned log container (previously relied on a third-party/shared container that apparently caused upload failures).
- **Hyprland 0.55 compatibility**: Fixed compatibility with Hyprland 0.55. Existing Hyprland configs were kept in their current format rather than being converted to Lua (Hyprland 0.55 introduced Lua-based config support, but Omarchy's configs remain in the traditional `.conf` format).
- **Boot channel selection**: Fixed cases where the boot process could place the system on the wrong update channel (e.g., stable vs. nightly/testing), which could lead users to receive unintended releases.

## Improvements

- **Log container ownership**: Moving log uploads to an Omarchy-owned container improves long-term reliability and control over the upload pipeline (related to the log-upload fix above).
