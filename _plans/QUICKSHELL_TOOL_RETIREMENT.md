# Quickshell — retiring the replaced tooling

**Status**: Open. The only outstanding item from the shell build.
**Extracted from**: `_plans/archive/QUICKSHELL_SHELL.md` Phase 6, on 2026-09-11, so that a live
decision stops living inside a frozen document. That plan is history; this file is the work.
**Prerequisite for the whole file**: each tool having *lived* replaced for about a month, so
nothing here is eligible before roughly 2026-10-01.

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

- [ ] `packages.yaml` entry removed; `package-manager sync --prune` reviewed **before** running
- [ ] Config directory and per-theme files removed across **all 8 themes** — `themes/CLAUDE.md`
      requires the set stay uniform, so a file removed from one goes from all
- [ ] Wrapper scripts, keybindings (`.conf` **and** `.lua`), autostart entries, menu entries
- [ ] Docs: `themes/CLAUDE.md` file list, `hypr/conf/bindings/README.md`, root `CLAUDE.md`
      Quick Reference (it names Waybar and Wofi as the desktop stack)
- [ ] One commit per tool, so a revert is one `git revert`
