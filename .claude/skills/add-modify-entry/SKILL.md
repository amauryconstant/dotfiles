---
name: add-modify-entry
description: Runbook for adding a new chezmoi modify_ entry — choosing chezmoi_modify_manager vs native modify-template, the mandatory ignore-before-add ordering rule, --smart-add usage, and safe validation via chezmoi cat (never logged). Use when the user asks to add a modify_ entry, wrap a config in chezmoi_modify_manager, or create a native modify-template.
allowed-tools: Read, Grep, Bash(chezmoi cat:*), Bash(chezmoi diff:*), Bash(chezmoi target-path:*), Bash(chezmoi source-path:*), Bash(chezmoi managed:*), Bash(chezmoi_modify_manager --help-syntax:*)
---

# Add a modify_ Entry

Procedure for adding a new `modify_` entry. `.claude/rules/chezmoi-modify-entries.md` is the semantics reference — read it first if unfamiliar. This skill is the step-by-step runbook.

`--smart-add` and Edit/Write are intentionally NOT pre-approved here — they mutate the source dir and should prompt normally.

## Step 1: Choose the kind

| Target format | Need | Kind |
|---|---|---|
| INI / key=value | Selective ignore or merge of live values | `chezmoi_modify_manager` |
| JSON / JSONC | Programmatic transform | native modify-template |
| Unsure | — | Default to `chezmoi_modify_manager` (4 of 6 existing entries use it) |

Worked examples in this repo:
- `chezmoi_modify_manager`: `private_dot_config/Nextcloud/modify_nextcloud.cfg.tmpl`, `private_dot_config/qt5ct/modify_qt5ct.conf.tmpl`
- native modify-template: `private_dot_config/opencode/modify_opencode.jsonc` (canonical — study this one first)

## Step 2: chezmoi_modify_manager path

1. Refresh directive syntax: `chezmoi_modify_manager --help-syntax`. There are exactly 8 directives: `source`, `ignore`, `set`, `remove`, `transform`, `add:remove`, `add:hide`, `no-warn-multiple-key-matches`. There is no `ignore_order` and no `self_update` directive.
2. **Write `ignore`/`add:remove`/`add:hide` directives into `.src.ini` BEFORE running `--smart-add`.** Re-add first and the live value gets written into tracked `.src.ini` — for a credential, that's one `git add` from being in history permanently. This ordering is not optional.
3. If the app writes `key=value` (no spaces), add `separator="="` to every `set` directive — there's no global default, and a missing separator means the file never converges (reappears in `merge-all`'s worklist forever).
4. `add:hide`/`add:remove` are NOT processed through chezmoi's template engine on re-add — `{{ if }}`-gating them silently does nothing.
5. Run `chezmoi_modify_manager --smart-add <target-path>` (expect a permission prompt — it mutates the source dir).
6. Validate: `chezmoi cat <target-path> > /dev/null`. Exit code only — see Step 4 below for the logging caution.

## Step 3: native modify-template path

1. Add the marker `{{- /* chezmoi:modify-template */ -}}` somewhere in the file. chezmoi removes every line containing the literal string `chezmoi:modify-template`; the wrapper comment syntax is convention, not required syntax.
2. **Never add a `.tmpl` suffix.** It suppresses `.chezmoi.stdin` (chezmoi issue #2563, closed *not planned*) — `modify_opencode.jsonc` having no suffix is load-bearing.
3. Template body reads the live file via `.chezmoi.stdin | fromJson` (or equivalent) and emits the merged result.
4. No `--smart-add` equivalent exists for this kind. Hand-edit the template after checking `chezmoi diff <target-path>`.
5. Validate: `chezmoi cat <target-path> > /dev/null`. Same logging caution as Step 2.

## Step 4: Common validation

- `chezmoi cat <target-path> > /dev/null` exits 0 → renders, executes, parses directives, merges cleanly.
- **Never let `chezmoi cat` output reach a log, terminal scrollback that gets pasted elsewhere, or a commit message.** For `modify_opencode.jsonc` specifically, the rendered output contains a decrypted API key.
- ❌ Do NOT use `chezmoi execute-template` to validate a `modify_` entry: it fails permanently on native modify-templates (`.chezmoi.stdin` is never set when the template itself comes from stdin), and it silently *passes* on `chezmoi_modify_manager`-kind corruption (raw INI/JSON is a valid template with zero actions — it won't catch a broken directive).
- Confirm the marker is still present after any hand-edit (native kind) or that the shebang line is intact (modify_manager kind) — losing either is what pre-commit's `chezmoi-sources` check regression-tests for.

## Common Mistakes

- `.tmpl` suffix on a native modify-template (breaks `.chezmoi.stdin`)
- `--smart-add` run before ignore/add:remove/add:hide directives exist in `.src.ini` (leaks the live value into git)
- Missing `separator="="` on a `set` directive against a `key=value` file (file never converges)
- Running `chezmoi merge` / `merge-all` on a `modify_` entry — guarded via `merge.command` in `.chezmoi.yaml.tmpl`, but the guard prevents corruption, it cannot repair an already-corrupt source
- Using `chezmoi execute-template` instead of `chezmoi cat` to validate
