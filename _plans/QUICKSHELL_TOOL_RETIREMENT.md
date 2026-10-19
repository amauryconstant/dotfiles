# Quickshell — retiring the replaced tooling

**Status**: wlogout, swaync, polkit-gnome, polkit-kde-agent and Waybar retired 2026-10-15 (one commit each, flags deleted). **Open**: Wofi (fallback, keep) and hyprlock (fallback again since 2026-10-19: the in-shell lock freeze on the desktop was the unbounded egl-wayland2 frame wait, fixed by running the shell on the patched build; **removal candidate** once that has lived about a month without a freeze, see the hyprlock row).
**Manual leftovers**: `paru -Rns waybar-git swaync wlogout polkit-gnome polkit-kde-agent` (`sync --prune` finds nothing here: no `package-state.yaml`), `systemctl --user unmask swaync.service`, `pkill waybar`, and the same on the laptop after `chezmoi apply`.
**Reviewed**: 2026-10-15 — every tool past its month and the go-ahead given: wlogout, swaync,
polkit-gnome, polkit-kde-agent and Waybar are retired in that order, one commit each, with their
feature flags (`quickshell_notifications`, `quickshell_polkit`, `quickshell_shell`) deleted and
ownership hardwired on. Wofi, cliphist and hyprlock stay. Gaps found in the review: wlogout was
also `quickshell-toggle`'s `power` fallback (now `user-interface/menu-system`); swaync was its
`notifications` fallback; `voxtype-waybar-status` no longer exists.
**Reviewed earlier**: 2026-09-13 — every path re-checked; three rows added
(hyprlock, polkit-gnome, polkit-kde-agent), none of which existed when the file was written.
**Extracted from**: `_plans/archive/QUICKSHELL_SHELL.md` Phase 6, on 2026-09-11, so that a live
decision stops living inside a frozen document. That plan is history; this file is the work.
**Prerequisite for the whole file**: each tool having *lived* replaced for about a month. The
Quickshell tree became the deployed shell on **2026-08-31**, so nothing here is eligible before
roughly **2026-10-01** — and the clock restarts per tool, not per repo: polkit and the lock screen
only moved into the shell on 2026-09-12.
**What each replaced tool actually did**, which is what a retirement has to confirm is still
covered: `_research/archive/QUICKSHELL_COMPONENT_MAPPING.md` (archived 2026-09-13; the left half of
each mapping is the part that stayed true).

---

## The rule

**Doing none of this is a valid end state.** Each replaced tool costs one package and one config
directory, and each is the fallback if the Quickshell replacement turns out worse in sustained use
than it looked on the day it shipped. Retirement is a separate, explicit decision **per tool**,
taken on an explicit go-ahead — never as a side effect of a Quickshell change.

Order below is easiest-to-reverse first.

---

## Per tool

| Tool | Eligible when | What goes | Keep? |
|---|---|---|---|
| **wlogout** | power menu has lived a month | `packages.yaml` entry, `private_dot_config/wlogout/`, `desktop/executable_wlogout`, `wlogout.css` × 8 themes | No. Fully replaced |
| **swaync** | notifications have lived a month | `packages.yaml`, `private_dot_config/swaync/`, the mask in `run_onchange_after_configure_notifications`, `swaync.css.tmpl` × 8 themes, the swaync bits of `desktop/executable_voxtype-waybar-status` | No. Fully replaced. Note this also removes the rollback path `features.quickshell_notifications: false` exists for |
| **Waybar** | the bar has lived a month | `packages.yaml`, `private_dot_config/waybar/`, `desktop/executable_waybar-toggle`, `executable_waybar-style`, `voxtype-waybar-status`, `hypr/conf.d/waybar.{lua,conf}`, the `.chezmoiignore` gate that picks between the two bars, `waybar.css` × 8 themes | No — but see the `waybar.css` trap below |
| **Wofi** | **not yet** | — | **Keep.** Still two live jobs: the fallback path in `desktop/quickshell-menu` when the socket is absent, and `SUPER+D` / `SUPER+C` in `hypr/conf/bindings/applications.*` for the Waybar branch. Removable only after Waybar goes and the fallback is deliberately dropped |
| **cliphist** | never | — | **Keep.** `ClipboardPicker.qml` is a front end for it, not a replacement — the shell deliberately does not own clipboard storage |
| **hyprlock** | the in-shell lock has lived about a month on the desktop (from **2026-10-19**) without a freeze | `packages.yaml`, `hypr/hyprlock.conf.tmpl`, `hyprlock.conf` × 8 themes, the `exec hyprlock` fallback branch of `desktop/immediate-lock`, the `PamContext config:"hyprlock"` borrow (see below) | **Keep for now, removal decided.** The desktop froze 2026-10-14 (670f0b2 pulled it back to hyprlock); the cause was the packaged egl-wayland2's unbounded frame wait, and `quickshell.service` now runs the patched build (`_research/FIREFOX_NVIDIA_EGL_DEADLOCK.md`), with `chassis: [laptop, desktop]` restored. `desktop/immediate-lock` still routes at *runtime*, so hyprlock is what locks the screen with the shell down or its restart budget spent, which is exactly what removal gives up: decide what `SUPER+L` does then. Removal also needs the shell's **own PAM file**: `/etc/pam.d/hyprlock` is shipped by the package, so deleting the package takes the lock's authentication with it (the `FileView` on it in `lock/LockScreen.qml` watches it too) |
| **polkit-gnome** | the shell's agent has lived a month | `packages.yaml`, `private_dot_config/hypr/conf.d/polkit-gnome.{lua,conf}`, the `.chezmoiignore` gate on `features.quickshell_polkit`, and the explanatory NOTE in `autostart.{lua,conf}` that says why no agent is started there | Same shape as swaync: removing it also removes the rollback path the feature flag exists for. A session holds exactly one agent, so there is no half-state to fall back to |
| **polkit-kde-agent** | now | `packages.yaml` line only | **Not a fallback — an orphan.** Installed, referenced by nothing in the tree (verified 2026-09-13), and it was already redundant before the shell existed. Removable independently of everything else here |

## 🚨 What `waybar.css` still holds

The original Phase 6 recorded this as a *generation* chain — `colors.sh` generated from
`waybar.css`. **That was wrong and the claim is now retracted in `colors.sh`'s own header**: no
such generator has ever existed here, and both files are hand-edited. What remains true is
weaker, but still an ordering constraint:

- **Four hover tints** (`@accent-*-hover`) are declared **only** in `waybar.css` and
  `swaync.css.tmpl`, per `themes/CLAUDE.md`. They are GTK-CSS-only by design and no `colors.sh`
  consumer sees them — so they die with the two tools that spend them, which is correct, but
  `themes/CLAUDE.md` documents them and must be edited in the same change.
- **`waybar.css` is the reference file for authoring a new theme** — `.claude/skills/new-theme`
  says to start there and propagate outward. Removing it without repointing that skill at
  `colors.sh` breaks theme authoring silently.

So: **removing `waybar.css` is a docs-and-skill change, not just a file deletion.** Do it in the
same commit as the Waybar package, or not at all.

## Per-tool checklist

- [ ] `packages.yaml` entry removed; `paru -Rns <pkg>` run by hand (`sync --prune` only sees packages `package-manager` itself installed — see `.claude/rules/chezmoi-scripts.md`)
- [ ] Config directory and per-theme files removed across **all 8 themes** — `themes/CLAUDE.md`
      requires the set stay uniform, so a file removed from one goes from all
- [ ] Wrapper scripts, keybindings (`.conf` **and** `.lua`), autostart entries, menu entries
- [ ] Docs: `themes/CLAUDE.md` file list, `hypr/conf/bindings/README.md`, root `CLAUDE.md`
      Quick Reference (it names Waybar and Wofi as the desktop stack)
- [ ] One commit per tool, so a revert is one `git revert`
