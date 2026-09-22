# chezmoi `modify_` Entries Reference

**Purpose**: `modify_*` covers **two unrelated mechanisms**. Conflating them corrupts files.
**See**: Root `CLAUDE.md` for core standards · `.claude/rules/chezmoi-templates.md` for template syntax

---

## The two kinds

|  | `chezmoi_modify_manager` script | native modify-template |
|---|---|---|
| Marker | `#!/usr/bin/env chezmoi_modify_manager` on line 1 | the **bare string** `chezmoi:modify-template` anywhere in the file |
| Provided by | third-party binary (AUR `chezmoi_modify_manager`) | chezmoi itself |
| Input | `.src.ini` in the **source dir** + current file on stdin | current file as `.chezmoi.stdin` |
| Language | directives (`source`, `ignore`, `set`, …) | Go template |
| Example | `private_dot_config/Nextcloud/modify_nextcloud.cfg.tmpl` | `private_dot_config/opencode/modify_opencode.jsonc` |
| Re-add | `chezmoi_modify_manager --smart-add <target>` | hand-edit source after `chezmoi diff` |

**Marker precision**: chezmoi removes *every line containing* `chezmoi:modify-template` and treats the rest as the template. The `{{- /* chezmoi:modify-template */ -}}` wrapper is convention, not syntax.

**Prefix order: `modify_` comes first.** `private_modify_settings.json` is *not* a modify entry — chezmoi reads it as a plain file literally named `modify_settings.json`. The type prefix leads, attributes follow: `modify_private_settings.json`. Verify with `chezmoi managed | grep <target>`; a wrong order shows the wrong target name and `chezmoi cat <real target>` answers `not managed`.

**🚨 Never add a `.tmpl` suffix to a native modify-template.** It suppresses `.chezmoi.stdin` — chezmoi issue [#2563](https://github.com/twpayne/chezmoi/issues/2563), closed *not planned*. `modify_opencode.jsonc` having no suffix is load-bearing, not an oversight.

---

### Never use `modify_` to share a file with a tool that checksums it

A modify-template re-serializes: `fromJson` → `toPrettyJson` sorts keys and normalizes layout, so the output is semantically equal to the input but never byte-equal. Any tool that records a hash of the bytes it wrote sees that as tampering.

`caveman doctor claude --fix` does exactly this — `~/.caveman/integrations/claude.json` stores `after_sha256` of `~/.config/claude/settings.json`. An apply through a modify-template preserved caveman's `env`/`hooks` intact and still flipped it to `owned: false` / `state: degraded`. Worse, the reinstall then refused: `claude PreToolUse Caveman hook changed after enable; refusing destructive disable`. Recovery was to restore the file to the manifest's `before_sha256` and re-run `--fix`.

Use `create_` for these files: chezmoi writes the seed only when the target is absent and never touches it again. See `private_dot_config/claude/create_private_settings.json`.

The trade is real — source edits never reach machines that already have the file. That is the correct trade when the file is app-managed state and only its initial content is ours.

`~/.config/claude/.claude.json` is Claude Code state and holds account credentials. It is untracked by chezmoi on purpose: never add, read, copy or render it.

---

## Never merge these

`chezmoi merge` / `merge-all` pass `.Source` = the raw source file, which for a `modify_` entry is the **generator**, while `.Destination`/`.Target` are rendered data. A three-way merge across those is a category error, and it has destroyed files in this repo.

There is **no `merge.exclude`** and no per-entry opt-out (`diff.exclude` exists; merge has only `merge.command`/`merge.args`). The guard is `.scripts/chezmoi-merge-guard.sh`, wired via `merge.command` — it refuses generators and delegates plain files to mergiraf.

The guard prevents corruption but **cannot repair it**: when a source is already corrupt, target-state computation fails and `merge-all` aborts before the guard runs. (The docs claim a two-way-merge fallback; `mergecmd.go` carries a `FIXME` saying it cannot.) Recovery is `git checkout HEAD -- <path>`.

`chezmoi re-add` is documented only as *"will not overwrite templates"* — it says nothing about `modify_`. Treat modify_-safety as **inference, not guarantee**, especially for generators without a `.tmpl` suffix.

---

## `chezmoi_modify_manager` semantics

Three files, two algorithms. `.src.ini` lives **in the source dir** next to the script (resolved from `CHEZMOI_SOURCE_DIR` + `CHEZMOI_SOURCE_FILE`), never in the destination.

**Merge** (on apply/diff/cat) — walks the live file from stdin:
- no action applies → take the value from `.src.ini`
- no action **and** absent from `.src.ini` → drop the line
- `ignore` → **leave the live system value as is** (so the diff is empty *because the value is copied through*, not because anything is excluded from diffing)

**Filter** (on `--add`/`--smart-add`) — decides what enters `.src.ini`:
- `ignore` implies `add:remove`; ignored lines are **not added back**, "in order to reduce git diffs"
- `add:remove` drops the key entirely; `add:hide` keeps the key and masks the value

**⚠ Ordering is mandatory**: add `ignore`/`add:remove`/`add:hide` directives **before** re-adding. Re-add first and the value is written into `.src.ini` — and for a credential, one `git add` from history.

**⚠ `add:hide`/`add:remove` are not processed through chezmoi's template engine on re-add**, so `{{ if }}`-gating them silently does nothing.

### Directives (exactly eight — verify with `--help-syntax`)

`source` · `ignore` · `set` · `remove` · `transform` · `add:remove` · `add:hide` · `no-warn-multiple-key-matches`

There is **no** `ignore_order` and **no** `self_update` directive. Self-update is the `-u/--upgrade` CLI flag.

### `separator=`

`set` defaults to `" = "`. If the owning application writes `key=value`, the file **never converges** and reappears in `merge-all`'s worklist forever. Use `set "S" "K" "V" separator="="`. No global default exists — repeat it on every `set`. Only `set` accepts it.

### Validation

There is **no** directive linter (`--help-syntax` is documentation; no `check`/`validate`/`--dry-run` exists). The closest thing is:

```sh
chezmoi cat <target-path> >/dev/null   # renders, executes, parses directives, merges
```

Do **not** use `chezmoi execute-template` to validate: it fails permanently on native modify-templates (`.chezmoi.stdin` is never set when the template itself comes from stdin), and it *passes* on rendered-output corruption, since raw INI/JSON are valid templates with zero actions.

Never let `chezmoi cat` output reach a log — for `opencode.jsonc` it emits a decrypted API key.

`chezmoi_modify_manager --doctor` checks the *environment*, not your files, and writes probe artifacts into the source dir. Manual troubleshooting only; not a pre-commit hook.

---

## Guardrails in this repo

| Layer | File |
|---|---|
| Merge guard | `.scripts/chezmoi-merge-guard.sh` (via `merge.command`) |
| Git merge driver | `.gitattributes` `modify_*` + `*.tmpl` → `.scripts/template-merge-driver.sh` |
| Pre-commit | `.mise/tasks/lint/chezmoi-sources.sh` — marker-loss regression vs HEAD, `chezmoi cat` render, gitleaks |

Corruption detection is **regression-based** (HEAD had a marker, staged does not). An absolute "must contain `{{ }}`" rule would false-positive on the six legitimately template-free tracked `.tmpl` files.
