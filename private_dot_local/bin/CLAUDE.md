# bin/ - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/bin/`
**Parent**: See `../CLAUDE.md` for CLI architecture overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## 🚨 No delegating wrappers

Every `lib/scripts/` category is already in PATH (`private_dot_config/shell/env`), so a wrapper
that only re-execs a script in PATH earns nothing — it just shadows the same name from an
earlier PATH entry. The last three (`ts`, `unzip`, `package-manager`) were removed 2026-09-14;
their targets now resolve directly:

| Command | Resolves to |
|---|---|
| `unzip` | `~/.local/lib/scripts/utils/unzip` |
| `package-manager` | `~/.local/lib/scripts/system/package-manager/package-manager` |
| `ts` | `~/.local/bin/ts` → `../lib/scripts/network/tailscale.sh` (symlink, not a wrapper) |

**For new scripts**: add to `lib/scripts/{category}/` as `executable_<name>` (no `.sh`).
Nothing in bin/ is needed to make it callable.

## What bin/ is for

Only two cases justify a file here:

1. **Overriding a system command** — the name must win over `/usr/bin`.
2. **Translating an incompatible CLI** — real argument rewriting, not pass-through.

A pure rename is neither: use `symlink_<name>` holding the relative target path.

## Contents

| File | Kind | Why it exists |
|---|---|---|
| `executable_firefox` | wrapper | NVIDIA egl-wayland2 workaround; shadows `/usr/bin/firefox`. Rebuilds the EGL platform config dir per launch. See the header comment — it is the record for `_research/FIREFOX_NVIDIA_EGL_DEADLOCK.md` |
| `symlink_firefox-esr` | symlink → `firefox` | **Load-bearing**: `executable_firefox` branches on `${0##*/}` to pick `firefox-esr`'s binary. Not a convenience alias |
| `executable_mmdc` | wrapper | Mermaid CLI shim — real flag translation (`-i/-o/--width/--height` → `mmdr`, format inferred from the output extension, `-b/-t/-s` dropped) |
| `symlink_ts` | symlink → `../lib/scripts/network/tailscale.sh` | Short name for the Tailscale helper (`ts up`, `ts down`, `ts status`). `tailscale.sh` reads no `$0`, so the symlink is transparent |

## Why no templates

**Chezmoi naming**: `executable_*` → mode 755; `*.tmpl` → template-processed.
A `executable_name.tmpl` would be both, adding template rendering to something that needs none.
Keep bin/ static; templates live in `lib/scripts/` (e.g. `desktop/executable_theme-switcher.tmpl`).

## Integration Points

- **`lib/scripts/`**: every implementation, directly in PATH
- **PATH + `SCRIPTS_DIR`/`UI_LIB`**: exported by `private_dot_config/shell/env`; PATH order is
  set by the `prepath` zstyle in `private_dot_config/zsh/dot_zstyles` (`~/.local/bin` first)
