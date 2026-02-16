Potential improvements — actionable ideas

## 1. The empty development/ category is a blank canvas

The script library has a development/ directory that's deliberately empty "for future expansion." This feels like the most underserved area of an otherwise rich environment. Some ideas:

- `project-create` — scaffold a new project (language detection, git init, mise setup, open in editor)
- `env-switch` — activate/deactivate project environments with direnv, virtualenv, or mise
- `worktree-manage` — manage git worktrees with a TUI (you already have `$worktrees` in globals.yaml)
- `dev-tunnel` — manage local reverse proxies via Tailscale (you have ts wrapper already)

## 2. Workspace autoname research is done but never implemented

`_research/AUTONAME-WORKSPACES_RESEARCH.md` exists. hyprwhenthen event system is live. The pieces are all there. Workspaces auto-named with app icons (Nerd Font glyphs) would make the keybindings.sh display and waybar workspace module significantly more informative.

## 3. No clipboard history

Weston/Wayland clipboard doesn't persist across app closes. You have wofi, you have the menu system — but no cliphist integration. A Super+V → wofi clipboard picker would fit perfectly into the existing trigger menu (menu-trigger.sh).

## 4. Named workspace "modes"

You have session-save / session-restore for arbitrary sessions. But no concept of preset modes — e.g., a focus-mode that kills chat apps + enables nightlight + sets gaps to 0, or a comms-mode that opens Signal/Discord on workspace 9. This is a menu-trigger.sh candidate with hyprwhenthen support.

## 5. The network/ category has only Tailscale

ts is a wrapper around tailscale. But there's no:
- `wifi-switch` — nmcli-based wifi network switcher (wofi menu)
- `vpn-toggle` — unified VPN status + toggle (Tailscale + any future WireGuard)
- `network-info` — local IP, Tailscale IP, ping diagnostics (fits system-health style)

## 6. No dotfiles-sync concept

You have chezmoi apply, but no one-shot pull-and-apply wrapper that: fetches remote, shows diff, confirms, applies, and optionally notifies on success. The menu-update.sh could check dotfiles updates (not just system packages) to complete the update story.

## 7. AI integration is fragmented

You have opencode, claude-code, ollama models — all configured. But there's no AI entry in system-menu. A menu-ai.sh that launches opencode/claude-code in a ghostty scratchpad, or pipes selected text to an LLM, would make this first-class. The hyprwhenthen float-and-center pattern already handles the popup window behavior.

## 8. Voice STT is planned but pending one unblock

The implementation plan is detailed and ready. The blocker is creating the GitLab repo. Everything else (hardware, model choice, chezmoi integration, Hyprland hotkey) is specced out. This is the highest-signal pending work.

## 9. terminal/ has only one script

terminal-cwd.sh is the sole terminal script. Candidates:
- `tmux-sessionizer` — fzf/wofi-based tmux session manager (popular pattern, fits the desktop)
- `ghostty-theme-preview` — preview and select ghostty themes interactively

## 10. Session management could be smarter

session-save/session-restore and session-prompt exist and are fairly sophisticated. But there's no session-list or session-diff — you can't see what was saved before restoring. A quick TUI preview before restore would be a natural fit.

## 11. Wallust integration is one-way

Wallust generates color palettes from wallpapers into hyprland.conf overrides, but those colors don't feed back into the theme system (waybar, dunst, etc.). A wallust-to-theme bridge that extracts a named scheme from wallust output and applies it through the theme system would complete the loop.

---

## Priority ranking (impact vs effort)

┌──────────┬──────────────────────────────────────────┬───────────────────┐
│ Priority │                   Item                   │      Effort       │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 🔥       │ Voice STT (just unblock the GitLab repo) │ Low               │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 🔥       │ Clipboard history (cliphist + wofi)      │ Low               │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ ⚡       │ Workspace autoname (research done)       │ Medium            │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ ⚡       │ Named workspace modes                    │ Medium            │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 💡       │ AI in system-menu                        │ Low               │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 💡       │ dotfiles-sync concept                    │ Low               │
├──────────┼──────────────────────────────────────────┼───────────────────┤
│ 💡       │ Session list/diff preview                │ Low               │
└──────────┴──────────────────────────────────────────┴───────────────────┘
