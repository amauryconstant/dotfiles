Potential improvements — actionable ideas

## 1. The empty development/ category is a blank canvas

The script library has a development/ directory that's deliberately empty "for future expansion." Some ideas:

- `project-create` — scaffold a new project (language detection, git init, mise setup, open in editor)
- `env-switch` — activate/deactivate project environments with direnv, virtualenv, or mise
- `worktree-manage` — manage git worktrees with a TUI (`$worktrees` = `~/Worktrees` in globals.yaml)
- `dev-tunnel` — manage local reverse proxies via Tailscale (ts wrapper already exists)

## 2. Workspace autoname research is done but never implemented

`_research/AUTONAME-WORKSPACES_RESEARCH.md` exists. Tool: `hyprland-autoname-workspaces` (AUR).
Integration point: Waybar's `hyprland/workspaces` module with `"format": "{name}"`.

Caveats: AUR-only (not official repos), no persistence across Hyprland restarts, requires manual icon mapping per app class, may conflict with `renameworkspace` dispatchers.

## 3. Named workspace "modes"

No implementation yet. The Toggle submenu in `menu-trigger` already has nightlight, idle, waybar, gaps —
a "mode" concept would slot in naturally there. Example modes: focus-mode (kill chat apps, gaps=0,
enable nightlight), comms-mode (open Signal/Discord on workspace 9). `session-save/restore` exists
but handles arbitrary snapshots, not preset configurations.

## 4. network/ remaining gaps

`wifi-switch` and `network-info` are done. Still missing:
- `vpn-toggle` — unified VPN status + toggle (Tailscale + any future WireGuard)

## 5. terminal/ remaining gaps

`tmux-sessionizer` is done. Still missing:
- `ghostty-theme-preview` — preview and select ghostty themes interactively

---

## Priority ranking (impact vs effort)

┌──────────┬──────────────────────────────────────────┬───────────────────┐
│ Priority │                   Item                   │      Effort       │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ ⚡       │ Workspace autoname (research done)       │ Medium            │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ ⚡       │ Named workspace modes                    │ Medium            │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 💡       │ vpn-toggle (Tailscale + WireGuard)       │ Low               │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 💡       │ ghostty-theme-preview                    │ Low               │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 💡       │ development/ scripts                     │ High              │
├──────────┼──────────────────────────────────────────┼───────────────────┤
└──────────┴──────────────────────────────────────────┴───────────────────┘
