# Hyprland Lua Configuration Reference

**Location**: `private_dot_config/hypr/`
**Lua files**: 40 files — themes, module configs, HyprDynamicMonitors profiles
**LSP config**: `private_dot_config/hypr/dot_luarc.json` (LuaJIT + Hyprland stubs)

**See**: Root `CLAUDE.md` for core standards
**See**: `private_dot_config/hypr/CLAUDE.md` for Hyprland overview

---

## Lua File Categories

| Pattern | Purpose | Count |
|---------|---------|-------|
| `conf/*.lua` | Hyprland module configs (loaded via `source`) | ~5 |
| `themes/*/hyprland.lua` | Per-theme color overrides | 8 |
| `hyprdynamicmonitors/*.lua` | Monitor profile definitions | varies |
| Neovim `*.lua` | Editor config (separate from Hyprland) | varies |

---

## Hyprland Lua Globals

The `.luarc.json` declares three globals for Hyprland's Lua API:

```lua
hl   -- Hyprland layout helpers
hs   -- Hyprland settings
o    -- Hyprland object/options
```

**LuaJIT runtime**: Hyprland uses LuaJIT (not standard Lua 5.x). LuaJIT is mostly compatible with Lua 5.1 + some 5.2 features.

---

## Theme Lua Pattern

Each theme provides a `hyprland.lua` that sets border colors using Hyprland's `$variables`:

```lua
-- Example: themes/rose-pine-moon/hyprland.lua
return {
  activeBorder   = "rgba(c4a7e7ee)",  -- iris (accent-border semantic)
  inactiveBorder = "rgba(6e6a86aa)",  -- muted (fg-muted semantic)
}
```

**Color format**: `rgba(hexee)` — 6-digit hex + 2-digit alpha, no `#` prefix.

**Semantic mapping**:
- `activeBorder` → `accent-border` semantic variable
- `inactiveBorder` → `fg-muted` semantic variable

---

## HyprDynamicMonitors Lua Profiles

Monitor profiles are Lua files describing display configurations:

```lua
-- Example profile
return {
  name = "home-desk",
  monitors = {
    { port = "DP-*", res = "2560x1440@144", scale = 1.0, pos = "0x0" },
    { port = "HDMI-*", res = "1920x1080@60", scale = 1.0, pos = "2560x0" },
  }
}
```

**Port matching**: Uses glob patterns (`DP-*`, `HDMI-*`) — port-agnostic, survives GPU changes.

---

## Validation Commands

```bash
# Check Lua syntax
lua -e "dofile('file.lua')" 2>&1

# Format Lua files (stylua)
stylua --check private_dot_config/hypr/**/*.lua

# Apply formatting
stylua private_dot_config/hypr/**/*.lua

# Lint with lua-language-server
lua-language-server --check private_dot_config/hypr/
```

---

## Stylua Config

If `.stylua.toml` doesn't exist, stylua uses defaults (2-space indent, 120 char line width).
Create `.stylua.toml` if custom formatting is needed:

```toml
indent_type = "Spaces"
indent_width = 2
column_width = 120
```

---

## Common Lua Issues in This Repo

**`hl`, `hs`, `o` undefined**: These are Hyprland globals — normal. LuaLS suppresses warnings via `.luarc.json` `diagnostics.globals`.

**LuaJIT vs Lua 5.4**: Avoid `<const>`, `<close>`, `table.move` with 5 args (5.4 features). Use `require` style imports only.

**Stubs location**: `/usr/share/hypr/stubs` — referenced in `.luarc.json`. If missing, install `hyprland` package.
