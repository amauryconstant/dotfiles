# Hyprland Lua Configuration Reference

**Location**: `private_dot_config/hypr/`
**Lua files**: themes, module configs, binding modules, HyprDynamicMonitors profiles
**LSP config**: `private_dot_config/hypr/dot_luarc.json` (LuaJIT + Hyprland stubs)

**See**: Root `CLAUDE.md` for core standards
**See**: `private_dot_config/hypr/CLAUDE.md` for Hyprland overview

---

## Lua File Categories

| Pattern | Purpose |
|---------|---------|
| `hypr/hyprland.lua.tmpl` | Entry point — `package.path` + `require` order (currently `.chezmoiignore`d) |
| `hypr/conf/*.lua` | Module configs, loaded via `require` (not `source` — that's the `.conf` path) |
| `hypr/conf/bindings/*.lua` | Binding modules, loaded by `require_all.files()` |
| `hypr/conf/{helpers,require_all}.lua` | Lua-layer infrastructure, no `.conf` twin |
| `hypr/conf.d/*.lua` | Drop-in overrides (e.g. voxtype submap) |
| `themes/*/hyprland.lua` | Per-theme border-color override |
| `hyprdynamicmonitors/hyprconfigs/*.lua` | Monitor profiles |
| Neovim `*.lua` | Editor config — unrelated to Hyprland |

---

## Hyprland Lua Globals

`.luarc.json` declares `hl`, `hs`, `o` in `diagnostics.globals`. What they actually are:

| Name | Reality |
|------|---------|
| `hl` | Hyprland's own API global — stubbed at `/usr/share/hypr/stubs/hl.meta.lua` |
| `o` | **Ours** — the ergonomic helper layer defined in `conf/helpers.lua` (`o.bind`, `o.window`, `o.exec_on_start`) |
| `hs` | hyprsplit — **not** actually a global; each consumer does its own `local hs = require("hyprsplit")`. The `.luarc.json` entry is legacy |

`o.bind(keys, description, dispatcher, opts)` wraps `hl.bind`: it folds `description` into
`opts.description` and auto-wraps a plain string dispatcher in `hl.dsp.exec_cmd`.

**LuaJIT runtime**: Hyprland uses LuaJIT (not standard Lua 5.x). LuaJIT is mostly compatible with Lua 5.1 + some 5.2 features.

---

## Theme Lua Pattern

Each theme's `hyprland.lua` is an **override module** — it calls `hl.config()` for effect. It does
**not** return a table; a `return {}` file loads and silently does nothing.

See: `private_dot_config/themes/rose-pine-moon/hyprland.lua`

```lua
hl.config({
    general = {
        col = {
            active_border   = "rgba(c4a7e7ee)",  -- iris (accent-border semantic)
            inactive_border = "rgba(6e6a86aa)",  -- muted (fg-muted semantic)
        },
    },
})
```

Loaded by `hyprland.lua.tmpl` via `require_all.if_exists(config .. "/themes/current/hyprland.lua", ...)`,
**after** `conf.general` — order matters, it overrides structural defaults.

**Semantic mapping**: `active_border` → `accent-border`, `inactive_border` → `fg-muted`.

### 🚨 Color format — 8 hex digits, not 10

Hyprland takes **8** hex digits (`rrggbb` + `aa`). A 10-digit `0xff<rrggbb><aa>` is **silently
truncated to the last 8**, dropping the leading `ff` and shifting every channel — no parse error,
just wrong colors. Rose-pine dawn/moon shipped this bug in both `.conf` and `.lua`; verified live
with `hyprctl getoption general:col.active_border` returning `907aa9ee`.

Always use `rgba(rrggbbaa)`. Verify a live value with `hyprctl getoption general:col.active_border`.

---

## HyprDynamicMonitors Lua Profiles

Profiles are **scripts of `hl.monitor()` calls**, not returned tables.

See: `private_dot_config/hyprdynamicmonitors/hyprconfigs/desktop-dual.lua`

```lua
hl.monitor({ output = "", mode = "3840x2160@144", position = "0x0", scale = 1.25 })
hl.monitor({ output = "", mode = "2560x1440@60", position = "3072x144", scale = 1, transform = 1 })
```

`output = ""` is Hyprland's "any output" wildcard, mirroring `monitor=,...` in the `.conf` twin.

**Port-agnostic matching happens in `config.toml`, not in the profile** — profile *selection* keys
off EDID `description` strings under `[[profiles.*.conditions.required_monitors]]`. There are no
glob port patterns (`DP-*`) anywhere. Rendered output goes to `~/.config/hypr/monitors.lua`
(`[general] destination`).

---

## Validation

All wired into mise (`.mise/config.toml`), scoped to `private_dot_config/hypr`:

| Task | What it does |
|------|--------------|
| `mise run lint:lua` | `stylua --check` on `*.lua`; `depends` on `lint:lua-tmpl`, so this one command covers every stylua check |
| `mise run lint:lua-tmpl` | renders each `*.lua.tmpl` and checks it (see below) |
| `mise run format:lua` | `stylua` apply — **`*.lua` only, by design** |
| `mise run lint:hypr-lua` | whole-tree parse check via `Hyprland --verify-config` — **manual-only**, see below |

⚠️ **Scope is `private_dot_config/hypr` only.** `themes/*/hyprland.lua` and
`hyprdynamicmonitors/hyprconfigs/*.lua` live outside it and are **not** linted or formatted — hence
the 4-space indent in the theme example above. Hyprland does not care; just don't assume a passing
`lint:lua` covered them.

### Formatting

No `.stylua.toml` exists, so stylua uses its defaults: **tabs**, 120-col. Match that when
hand-editing files under `hypr/` — 2-space indent fails `--check`.

### Templates (`*.lua.tmpl`)

`find -name '*.lua'` does not match `*.lua.tmpl`, and stylua cannot read a template directly (Go
template actions aren't valid Lua). `.mise/tasks/lint/lua-tmpl-file.sh` renders one first:
`chezmoi execute-template … | stylua --check --stdin-filepath <name minus .tmpl> -`.
`lua-staged.sh` dispatches staged `.tmpl` files to it, so pre-commit covers them too.

**Check-only, never formatted in place** — rendering discards the template actions, so there is
nothing for stylua to write back to.

**Limitation**: only the branch that renders *for the current machine* is checked. A
`{{ if ne .chassisType "laptop" }}` block is invisible when linting on the laptop. Check both
branches by hand when editing gated code.

Adding this check immediately caught four previously-invisible defects: `hyprland.lua.tmpl` on
2-space indent with aligned trailing comments; two over-120-col lines in `applications.lua.tmpl`;
and missing whitespace control in `monitor.lua.tmpl` (`{{ else }}` → `{{- else -}}`, `{{ end }}` →
`{{- end }}`) that emitted stray blank lines in *both* rendered branches.

### Whole-tree parse check

`mise run lint:hypr-lua` wraps `Hyprland --verify-config` ("Do not run Hyprland, only print if the
config has any errors"). The Lua entry point is `.chezmoiignore`d (see
`_research/HYPRLAND_LUA_MIGRATION.md`), so the task renders it to a temp path; `package.path`
resolves the rest of the tree against the deployed `~/.config/hypr`:

```bash
TMP=$(mktemp -d)
chezmoi execute-template --source "$(git rev-parse --show-toplevel)" \
 < private_dot_config/hypr/hyprland.lua.tmpl > "$TMP/hyprland.lua"
Hyprland --verify-config -c "$TMP/hyprland.lua"
```

Proves the tree parses and every `require` resolves. Does **not** prove dispatcher arguments are
right — the stub types every dispatcher as `fun(...): HL.Dispatcher` (untyped varargs), so a wrong
argument passes LuaLS, stylua and `--verify-config` alike, and only shows up at runtime.

`--source` is load-bearing: without it `execute-template` renders against the *global* chezmoi
source dir, which silently lints the wrong tree from a worktree or second clone.

**Deliberately not in `[tasks.lint].depends`** — unlike every other task in the table, it needs the
`Hyprland` binary *and* a deployed `~/.config/hypr` for `package.path` to resolve. `mise run lint`
does not run it; invoke it by hand.

---

## Common Lua Issues in This Repo

**`Undefined global 'o'` while editing a source file**: expected. The globals *are* declared, but
the source-tree file is named `dot_luarc.json` (chezmoi naming) and LuaLS looks for `.luarc.json`,
so it never loads it under `private_dot_config/hypr/`. The **deployed** `~/.config/hypr/.luarc.json`
works fine. Deliberately not duplicated as a second file — ignore the diagnostic, or edit via
`chezmoi edit`.

**LuaJIT vs Lua 5.4**: Avoid `<const>`, `<close>`, `table.move` with 5 args (5.4 features). Use `require` style imports only.

**Stubs location**: `/usr/share/hypr/stubs` — referenced in `.luarc.json`. If missing, install `hyprland` package.
