---
name: apply
description: Deploy runbook for this chezmoi repo — summarise the pending diff by area, hand the user the `chezmoi apply` (Claude may not run it), then run the follow-ups the changed paths require (Quickshell restart, Hyprland reload, systemd daemon-reload) and verify the result. Invoke explicitly with /apply after committing or editing source.
disable-model-invocation: true
allowed-tools: Read, Bash(chezmoi diff:*), Bash(chezmoi status:*), Bash(chezmoi managed:*), Bash(git status:*), Bash(git log:*), Bash(hyprctl layers:*), Bash(hyprctl monitors:*), Bash(hyprctl getoption:*), Bash(mise run lint:hypr-lua:*), Bash(quickshell -c dotfiles ipc show:*), Bash(systemctl --user status:*), Bash(systemctl --user show:*)
---

# Apply

`chezmoi apply` is denied for Claude on purpose. This skill prepares it, hands it to the user, then finishes the job — an apply alone leaves several things stale (notably a running Quickshell, see `.claude/rules/quickshell-qml.md`).

> Visual change to `hypr/`, `quickshell/` or `themes/`? Run it in the `desk` sandbox first (`/desk` skill), so the live session is not the first place it renders.

## 1. Review the diff — never apply blind

```bash
chezmoi status
chezmoi diff
```

Summarise **by area** (hypr, quickshell, themes, systemd/user, scripts, `.chezmoidata`, packages…), not file by file. Flag:

- `modify_*` and generator entries — render with `chezmoi cat <target> >/dev/null` to prove they still render. Never print the output (opencode renders a decrypted key; a hook blocks it).
- `encrypted_*` / `.age` targets — never read or diff their content.
- `run_onchange_*` scripts whose hash input changed — name which will fire and what they do (`packages.yaml` → package sync; `mise.yaml` → `mise install`; …).
- Nothing to apply (`chezmoi status` empty) → say so and stop.

## 2. Hand over the apply

Ask the user to run it themselves: **`! chezmoi apply`**. Do not run it, and do not continue until they confirm it finished (or paste its error).

## 3. Follow-ups, chosen from the changed target paths

| Changed | Do |
|---|---|
| `private_dot_config/quickshell/**` | `desktop/quickshell-restart` — the only reload path (the file watcher is off). It refuses while the session is locked; never a bare `systemctl --user restart quickshell.service`. Ask the user to run it |
| `private_dot_config/hypr/**`, `themes/*/hyprland.*`, `hyprdynamicmonitors/**` | `hyprctl reload`, then `mise run lint:hypr-lua`. Theme colours: `hyprctl getoption general:col.active_border` |
| `private_dot_config/systemd/user/**` | `systemctl --user daemon-reload`, then restart the affected unit (user runs it) |
| `.chezmoidata/packages.yaml` | Additions install via the sync script. **Removals do nothing** — remind the user that `paru -Rns <pkg>` is manual, per machine |
| `.chezmoiscripts/**` | Say which `run_once_*` are new (renumbering re-runs them) |
| themes | `theme switch`/`theme-apply-*` regenerate consumers; a Quickshell theme change needs `quickshell -c dotfiles ipc call theme reload` |

## 4. Verify against reality, not the files

- Quickshell: `quickshell -c dotfiles ipc show` lists the expected targets (`ipc call` exits 0 even when it fails); `hyprctl layers` shows the bar.
- Hyprland: `hyprctl monitors` / `hyprctl getoption …` for the value that changed.
- Report what was verified and what was only inferred. A file on disk being correct is not a pass.
