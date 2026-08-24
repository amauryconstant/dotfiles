# Omarchy v3.8.4 — Release Research

**Date researched**: 2026-08-24
**Previous version**: v3.8.3
**Commits**: 9
**Source**: GitHub release notes

---

## Summary

Patch release consisting entirely of bug fixes. It repairs a Neovim theme symlink that pointed at an Omarchy 4 path (breaking plugin loading on 3.x), unblocks the RetroArch gaming installer by dropping libretro cores that no longer exist in the repos, corrects the `nvim` package name to `neovim`, hardens the Foot terminal text-bindings migration, and makes the Waybar toggle reliably kill the bar.

## Breaking Changes

*None*

## Bug Fixes

- **Neovim theme symlink pointed at Omarchy 4 location**: `omarchy-nvim` briefly created `~/.config/nvim/lua/plugins/theme.lua` as a symlink to `~/.local/state/omarchy/current/theme/neovim.lua` (the Omarchy 4 path), which does not exist on 3.x, so Neovim failed to load `plugins.theme` at startup (upstream issue #6309). A new migration retargets the link to the 3.x relative path `../../../../.config/omarchy/current/theme/neovim.lua`, and leaves the link untouched if it was customized. Omarchy path: `migrations/1784518937.sh`
- **RetroArch installer failed on dropped packages**: Three libretro cores that are no longer available (`libretro-bsnes2014`, `libretro-mame2016`) caused the installer to abort. Removed from both the add and drop package lists. Omarchy paths: `bin/omarchy-install-gaming-retroarch`, `bin/omarchy-remove-gaming-retroarch`
- **Incorrect Neovim package name in base package list**: `nvim` replaced with `neovim` in the base install manifest. Omarchy path: `install/omarchy-base.packages`
- **Foot bindings migration used a fragile sed append**: The `[text-bindings]` section header was appended via `sed -i '$a\\\n[text-bindings]'`, which misbehaves depending on trailing-newline state. Replaced with `printf '\n[text-bindings]\n' >> "$foot_config"`. Omarchy path: `migrations/1783833508.sh`
- **Waybar not restarting correctly on toggle**: Newer Waybar does not exit on `SIGTERM` in this path, so the toggle left a stale process and the bar never came back. `pkill -x waybar` changed to `pkill -9 -x waybar`. Omarchy path: `bin/omarchy-toggle-waybar`

## Configuration Changes

- **Neovim theme symlink target (Omarchy 3.x)**: Expected target is `~/.config/omarchy/current/theme/neovim.lua` (written as the relative path `../../../../.config/omarchy/current/theme/neovim.lua`), not the Omarchy 4 `~/.local/state/omarchy/current/theme/neovim.lua`. Omarchy path: `migrations/1784518937.sh`
- **Foot `[text-bindings]` section creation**: Section header now appended with `printf` instead of `sed` line-append; the subsequent CSI-u binding inserts (`\x1b[13;2u=Shift+Return`, `\x1b[13;4u=Mod1+Shift+Return`) are unchanged. Omarchy path: `migrations/1783833508.sh`

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Renamed | `nvim` → `neovim` | Correct Arch package name in base manifest |
| Removed | `libretro-bsnes2014` | Package dropped upstream; blocked RetroArch install |
| Removed | `libretro-mame2016` | Package dropped upstream; blocked RetroArch install |
