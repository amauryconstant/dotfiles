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

## Step 3: Recolor semantic variables

Full 24-variable schema (Background: `@bg-primary/secondary/tertiary/overlay`; Foreground: `@fg-primary/secondary/muted/contrast`; 8 Core + 8 Extended accents; 4 hover variants) is defined in `themes/CLAUDE.md`. Start with `waybar.css` — it's the most complete single-file reference — then propagate the same hex values into every other file in the theme dir.

**`colors.sh` is a second vocabulary, and the one Quickshell and the shell scripts read**: semantic ROLE keys, not CSS names — `GROUND_BASE/RAISED/FLOAT`, `FILL_INERT`, `INK_PRIMARY/SECONDARY/MUTED/CONTRAST_CANDIDATE`, `SIGNAL_FOCUS/ERROR/WARN/OK/INFO`, `IDENTITY_1`…`_5`. Copy the key set from `rose-pine-moon/colors.sh` and map by role, never by name (see `themes/CLAUDE.md` → "Two vocabularies, one palette"). A missing key silently falls back to Catppuccin in `Theme.qml`.

## Step 4: Pick palette + check contrast (mandatory)

**Rule**: elevated surfaces (`@bg-secondary`, `@bg-tertiary`, `@bg-overlay`) MUST pair with `@fg-primary` for all text/icons. `@fg-secondary` on an elevated surface fails WCAG AA (4.5:1) on several existing themes.

Compute the contrast ratio of your `@fg-secondary` against your `@bg-secondary`. If it's below 4.5:1, document the theme as "Use PRIMARY only" in its `STYLE-GUIDE.md`, following the precedent already set by Catppuccin Latte, Rose Pine Dawn, Rose Pine Moon, and Solarized Light (see the ratio table in `themes/CLAUDE.md`).

Then run `mise run lint:theme-contrast` — it measures the pairs Quickshell actually renders across every colorset, including the new one. Manual-only, so it is not part of `mise run lint`.

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

## Step 6: `swaync.css.tmpl`

The **only** templated file in a theme dir — injects `.globals.*` fonts. Copy the `{{ }}` blocks verbatim from the base theme; only recolor the literal CSS values around them. Validate:

```bash
chezmoi execute-template < private_dot_config/themes/<new-name>/swaync.css.tmpl > /dev/null
```

## Step 7: Registration

Five scripts hardcode exact theme names in `case` arms and will silently no-op (or fall back to a default) for an unregistered theme — this is NOT covered by the file-set check in Step 2.

```bash
bash scripts/check-registrations.sh <new-name>
```

Reports ✅/❌ per file across: `theme-apply-gtk`, `theme-apply-claude-code`, `theme-apply-spotify`, `theme-apply-qt` (all `case "$THEME_NAME" in ...`), `dotfiles_theme.lua`'s theme map, `dark-mode.d`/`light-mode.d`'s `01-switch-theme.sh` (only relevant for irregular light↔dark name pairs — standard `-light`/`-dark`-suffixed pairs may already resolve generically, check the script's own logic), and `run_once_before_007_setup_default_theme.sh.tmpl` (low-priority — fresh-machine bootstrap dir creation only). `theme-apply-opencode`, `-firefox`, `-neovim` are name-agnostic and need no change.

## Step 8: Validate

```bash
mise run lint:lua-file -- private_dot_config/themes/<new-name>/hyprland.lua
```

Consider running the `theme-consistency-reviewer` subagent before committing — it checks the same file-set/contrast/format rules end to end.

## Step 9: Wallpapers

Curate wallpapers into `~/.config/wallpapers/<new-name>/`, per the guidance in the new theme's own (cloned) `wallpapers/README.md`. `organize-wallpapers-by-color.sh` is a one-time historical tool, not part of this workflow.
