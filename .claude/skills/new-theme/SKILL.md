---
name: new-theme
description: Scaffold a new dotfiles theme by cloning an existing theme directory, recoloring every semantic variable under the WCAG contrast rules, and registering the theme in the handful of scripts that hardcode theme names. Side-effecting generator — invoke explicitly with /new-theme, never auto-triggered.
disable-model-invocation: true
allowed-tools: Read, Bash(find:*), Bash(diff:*), Bash(comm:*), Bash(chezmoi execute-template:*)
---

# New Theme

Invoke as `/new-theme <name>`. Side-effecting — creates files and edits scripts across the repo. Reference: `private_dot_config/themes/CLAUDE.md`, `.claude/rules/hyprland-lua.md`.

## Step 1: Pick a base to clone

Dark bases: `catppuccin-mocha`, `gruvbox-dark`, `rose-pine-moon`, `solarized-dark`. Light bases: `catppuccin-latte`, `gruvbox-light`, `rose-pine-dawn`, `solarized-light`.

```bash
cp -r private_dot_config/themes/<base>/ private_dot_config/themes/<new-name>/
```

## Step 2: Verify the file set

```bash
bash scripts/check-theme-files.sh <new-name>
```

Diffs against a live reference theme dir (default `rose-pine-moon`), not a hardcoded list — `themes/CLAUDE.md`'s documented file set has drifted from reality before, so a real directory is the only trustworthy source of truth. Right after a `cp -r` this should report a clean match; re-run after any file additions/removals.

## Step 3: Recolor — `colors.sh` first

`colors.sh` is the role layer and the one Quickshell (`Theme.qml`) and the shell scripts read: **18 keys**, named by ROLE — `GROUND_BASE/RAISED/FLOAT`, `FILL_INERT`, `INK_PRIMARY/SECONDARY/MUTED/CONTRAST_CANDIDATE`, `SIGNAL_FOCUS/ERROR/WARN/OK/INFO`, `IDENTITY_1`…`_5`. Copy the key set from `rose-pine-moon/colors.sh` and map by role, never by CSS name (see `themes/CLAUDE.md` → "Two vocabularies, one palette"). A missing key silently falls back to Catppuccin in `Theme.qml`.

Then carry the same palette into the CSS-vocabulary file `wofi.css` (24 `@define-color`: `@bg-*`, `@fg-*`, `@accent-*`) and propagate the hex values into every other file in the theme dir. The two vocabularies have no translation layer — keep them in step by hand.

## Step 4: Check contrast (mandatory)

**Rule**: elevated surfaces (`@bg-secondary`, `@bg-tertiary`, `@bg-overlay`) MUST pair with `@fg-primary` for all text/icons. `@fg-secondary` on an elevated surface fails WCAG AA (4.5:1) on several existing themes. If your `@fg-secondary` against `@bg-secondary` is below 4.5:1, document the theme as "Use PRIMARY only" in its `STYLE-GUIDE.md` (precedent: Catppuccin Latte, Rose Pine Dawn/Moon, Solarized Light; ratio table in `themes/CLAUDE.md`).

Run `mise run lint:theme-contrast` (`-- --report` for the tables). It reads every colorset, including the new one, and is part of `mise run lint`. Fix any failure in `colors.sh`; do not excuse it.

## Step 5: `hyprland.lua` format

An override module that calls `hl.config()` for effect — a file that `return`s a table loads and silently does nothing:

```lua
hl.config({
	general = {
		col = {
			active_border = "rgba(HEXee)", -- accent-border semantic
			inactive_border = "rgba(HEXaa)", -- fg-muted semantic
		},
	},
})
```

8 hex digits (`rrggbbaa`), no `#`, tabs (stylua). See `.claude/rules/hyprland-lua.md`.

## Step 6: Registration

Several scripts hardcode exact theme names in `case` arms and will silently no-op (or fall back to a default) for an unregistered theme — this is NOT covered by the file-set check in Step 2.

```bash
bash scripts/check-registrations.sh <new-name>
```

Reports ✅/❌ per file across: `theme-switcher`'s `theme_variant()` (**load-bearing** — GTK, Qt and Claude Code switch on its dark/light/other answer, and an unknown theme gets `other`), `theme-apply-spotify`, `dotfiles_theme.lua`'s theme map, `dark-mode.d`/`light-mode.d`'s `01-switch-theme.sh` (only relevant for irregular light↔dark name pairs — standard `-light`/`-dark` suffixes resolve generically), and `run_once_before_007_setup_default_theme.sh.tmpl` (low-priority — fresh-machine bootstrap only). `theme-apply-gtk`/`-qt`/`-claude-code` read the variant, and `-opencode`, `-firefox`, `-neovim` are name-agnostic; none need a change.

## Step 7: Validate

```bash
mise run lint:lua-file -- private_dot_config/themes/<new-name>/hyprland.lua
```

Consider running the `theme-consistency-reviewer` subagent before committing — it checks the same file-set/contrast/format rules end to end.

## Step 8: Wallpapers

Curate wallpapers into `~/.config/wallpapers/<new-name>/`, per the guidance in the new theme's own (cloned) `wallpapers/README.md`. `organize-wallpapers-by-color.sh` is a one-time historical tool, not part of this workflow.
