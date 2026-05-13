# Hyprland Lua Config Migration Plan

## Background

Hyprland 0.55 deprecated hyperlang in favour of Lua. Hyperlang support will be dropped within **1–2 releases after 0.55** (est. 0.57). No new hyperlang features will be added.

- `hyprland.conf` → `hyprland.lua` (only Hyprland itself migrates)
- `hypridle.conf`, `hyprlock.conf` **stay hyperlang** (Hypr* utilities keep hyperlang)
- HyprDynamicMonitors, hyprwhenthen configs **stay hyperlang**

**Sources**: [0.55 announcement](https://hypr.land/news/update55/) · [Lua news](https://hypr.land/news/26_lua/) · [Wiki](https://wiki.hypr.land/Configuring/Start/)

**LSP stubs**: `/usr/share/hypr/stubs/` — configure `.luarc.json` for autocompletion.

---

## Scope

### Files to Migrate (21 total)

| Current file | New file | Notes |
|---|---|---|
| `hyprland.conf.tmpl` | `hyprland.lua.tmpl` | Main entry, Go template retained |
| `conf/environment.conf` | `conf/environment.lua` | 14 `env =` → `hl.env()` |
| `conf/monitor.conf.tmpl` | `conf/monitor.lua.tmpl` | Go template conditional retained |
| `conf/autostart.conf` | `conf/autostart.lua` | `exec-once` → `hl.exec_cmd()` in startup event |
| `conf/input.conf` | `conf/input.lua` | `hl.config({ input = {...} })` |
| `conf/general.conf` | `conf/general.lua` | Needs theme color injection |
| `conf/decoration.conf` | `conf/decoration.lua` | Nested blur/shadow tables |
| `conf/animations.conf` | `conf/animations.lua` | `hl.curve()` + `hl.animation()` |
| `conf/plugins.conf` | `conf/plugins.lua` | `local hs = require("hyprsplit")` |
| `conf/windowrules.conf` | `conf/windowrules.lua` | `hl.window_rule()` + layer rules |
| `conf/bindings/applications.conf.tmpl` | `conf/bindings/applications.lua.tmpl` | Go template retained |
| `conf/bindings/desktop-utilities.conf` | `conf/bindings/desktop-utilities.lua` | |
| `conf/bindings/focus-navigation.conf` | `conf/bindings/focus-navigation.lua` | |
| `conf/bindings/media-keys.conf` | `conf/bindings/media-keys.lua` | |
| `conf/bindings/screenshots.conf` | `conf/bindings/screenshots.lua` | |
| `conf/bindings/system-control.conf` | `conf/bindings/system-control.lua` | |
| `conf/bindings/theme-session.conf` | `conf/bindings/theme-session.lua` | |
| `conf/bindings/voice.conf` | `conf/bindings/voice.lua` | |
| `conf/bindings/window-management.conf` | `conf/bindings/window-management.lua` | |
| `conf/bindings/window-resizing.conf` | `conf/bindings/window-resizing.lua` | |
| `conf/bindings/workspace-management.conf` | `conf/bindings/workspace-management.lua` | hyprsplit Lua API |
| `conf.d/voxtype-submap.conf` | `conf.d/voxtype-submap.lua` | `hl.define_submap()` |

### Files NOT Migrating

| File | Reason |
|---|---|
| `hypridle.conf.tmpl` | hypridle stays hyperlang |
| `hyprlock.conf.tmpl` | hyprlock stays hyperlang |
| `themes/*/hyprland.conf` | Keep as-is; add sibling `.lua` files |

### New Files to Create

| File | Purpose |
|---|---|
| `themes/*/hyprland.lua` (×8) | Lua color module for border injection |
| `themes/catppuccin-latte/hyprland.lua` | |
| `themes/catppuccin-mocha/hyprland.lua` | |
| `themes/gruvbox-dark/hyprland.lua` | |
| `themes/gruvbox-light/hyprland.lua` | |
| `themes/rose-pine-dawn/hyprland.lua` | |
| `themes/rose-pine-moon/hyprland.lua` | |
| `themes/solarized-dark/hyprland.lua` | |
| `themes/solarized-light/hyprland.lua` | |
| `.luarc.json` in `hypr/` | LSP autocompletion for hyprland stubs |

---

## API Translation Reference

### Core Functions

| Hyperlang | Lua |
|---|---|
| `env = VAR,value` | `hl.env("VAR", "value")` |
| `source = file` | `dofile(os.getenv("HOME") .. "/.config/hypr/conf/file.lua")` |
| `monitor = name,mode,pos,scale` | `hl.monitor({ output="name", mode="mode", position="pos", scale=N })` |
| `exec-once = cmd` | `hl.exec_cmd("cmd")` inside `hl.on("hyprland.start", function() ... end)` |
| `windowrule = match:class X, float on` | `hl.window_rule({ match = { class = "X" }, float = true })` |
| `layerrule = match:namespace = X, blur 1` | *(see Open Questions — not documented yet)* |

### hl.config() Structure

```lua
hl.config({
    general = {
        gaps_in = 4, gaps_out = 8, border_size = 2,
        layout = "dwindle",
        col = { active_border = theme.activeBorder, inactive_border = theme.inactiveBorder }
    },
    decoration = {
        rounding = 8,
        blur = { enabled = true, size = 5, passes = 2, vibrancy = 0.1696 },
        shadow = { enabled = true, range = 4, render_power = 3, color = "rgba(1a1a1aee)" }
    },
    input = {
        kb_layout = "us", numlock_by_default = true, follow_mouse = 1, sensitivity = 0,
        touchpad = { natural_scroll = false }
    },
    dwindle = { preserve_split = true },
    animations = { enabled = true }
})
```

### Dispatcher Mapping

| Hyperlang dispatcher | Lua dispatcher |
|---|---|
| `exec, cmd` | `hl.dsp.exec_cmd("cmd")` |
| `killactive` | `hl.dsp.window.close()` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `fullscreen, 0` | `hl.dsp.window.fullscreen({ mode = 0 })` |
| `movefocus, l/r/u/d` | `hl.dsp.focus({ direction = "l" })` |
| `movewindow, l/r/u/d` | `hl.dsp.window.move({ direction = "l" })` |
| `resizeactive, -20 0` | `hl.dsp.window.resize({ x = -20, y = 0, relative = true })` |
| `togglespecialworkspace, magic` | `hl.dsp.workspace.toggle_special("magic")` |
| `movetoworkspace, special:magic` | `hl.dsp.window.move({ workspace = "special:magic" })` |
| `focusmonitor, l/r/u/d` | `hl.dsp.focus({ monitor = "l" })` |
| `changegroupactive, b` | `hl.dsp.group.prev()` |
| `changegroupactive, f` | `hl.dsp.group.next()` |
| `submap, name` | `hl.dsp.submap("name")` |
| `workspace, e+1` | `hl.dsp.focus({ workspace = "e+1" })` *(verify)* |
| `movecurrentworkspacetomonitor, l` | *(verify — not in docs)* |
| `split:workspace, N` | `hs.dsp.focus({ workspace = N })` |
| `split:movetoworkspacesilent, N` | `hs.dsp.window.move({ workspace = N, follow = false })` |
| `split:swapactiveworkspaces, current +1` | `hs.dsp.workspace.swap_monitors({ monitor1 = "current", monitor2 = "+1" })` |
| `split:grabroguewindows` | `hs.dsp.grab_rogue_windows()` |

### Bind Syntax

```lua
-- bindd equivalent (with description)
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })

-- bindm equivalent (mouse)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Flags
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("..."), { repeating = true })
hl.bind("switch:on:[switch name]", hl.dsp.exec_cmd("..."), { locked = true })
```

### Animations

```lua
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, curve = "default", style = "popin 80%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
```

### hyprsplit Lua API

```lua
local hs = require("hyprsplit")
hs.config({ num_workspaces = 10, persistent_workspaces = false })
-- Dispatcher: hs.dsp.focus(), hs.dsp.window.move(), hs.dsp.workspace.swap_monitors(), hs.dsp.grab_rogue_windows()
```

### Submap (for voxtype)

```lua
hl.define_submap("voxtype_recording", function()
    hl.bind("F12", hl.dsp.exec_cmd("voxtype record cancel"))
    hl.bind("F12", hl.dsp.submap("reset"))
    hl.bind("SUPER + T", hl.dsp.exec_cmd("voxtype record stop"), { release = true })
    hl.bind("SUPER SHIFT + T", hl.dsp.exec_cmd("voxtype record stop"), { release = true })
    hl.bind("SUPER CTRL + T", hl.dsp.exec_cmd("voxtype record stop"), { release = true })
end)
```

---

## Phases

### Phase 0: Preparation

1. Verify current Hyprland version: `hyprctl version`
2. Set up LSP stubs: create `private_dot_config/hypr/.luarc.json` pointing to `/usr/share/hypr/stubs/`
3. Confirm `hyprland.lua` takes priority when present — do NOT delete `.conf` until validated
4. Create git branch for migration work

**Coexistence**: Hyprland loads `hyprland.lua` if present, else `hyprland.conf`. Keep `.conf` intact until `.lua` is validated.

### Phase 1: Theme System Extension

**Goal**: Each theme directory gets a `hyprland.lua` that exposes border colors as a Lua module.

**File format** (add to each of 8 theme directories):
```lua
-- ~/.config/themes/{variant}/hyprland.lua
return {
    activeBorder   = "rgba(b4befeee)",
    inactiveBorder = "rgba(9399b2aa)",
}
```

Extract values from the existing `$activeBorder` / `$inactiveBorder` lines in each theme's `hyprland.conf`.

**Themes**: catppuccin-latte, catppuccin-mocha, gruvbox-dark, gruvbox-light, rose-pine-dawn, rose-pine-moon, solarized-dark, solarized-light

Theme switcher does not need changes (symlink update already covers the `current/` directory).

### Phase 2: Main Entry Point

**New file**: `hyprland.lua.tmpl`

```lua
-- Load theme colors (sourced from current theme symlink)
local theme = dofile(os.getenv("HOME") .. "/.config/themes/current/hyprland.lua")

local cfg = os.getenv("HOME") .. "/.config/hypr/conf/"

-- Load conf.d overrides (e.g. voxtype-submap)
local conf_d = io.popen('ls "' .. os.getenv("HOME") .. '/.config/hypr/conf.d/"*.lua 2>/dev/null')
if conf_d then
    for f in conf_d:lines() do pcall(dofile, f) end
    conf_d:close()
end

-- Core config (order matters: theme before general)
dofile(cfg .. "environment.lua")
{{ if eq .chassisType "desktop" }}
dofile(os.getenv("HOME") .. "/.config/hypr/monitors.lua")
{{ end }}
dofile(cfg .. "monitor.lua")
dofile(cfg .. "autostart.lua")
dofile(cfg .. "plugins.lua")
dofile(cfg .. "input.lua")
dofile(cfg .. "general.lua")       -- reads theme
dofile(cfg .. "decoration.lua")
dofile(cfg .. "animations.lua")

-- Keybindings
local b = cfg .. "bindings/"
dofile(b .. "applications.lua")
dofile(b .. "desktop-utilities.lua")
dofile(b .. "focus-navigation.lua")
dofile(b .. "media-keys.lua")
dofile(b .. "screenshots.lua")
dofile(b .. "system-control.lua")
dofile(b .. "theme-session.lua")
dofile(b .. "voice.lua")
dofile(b .. "window-management.lua")
dofile(b .. "window-resizing.lua")
dofile(b .. "workspace-management.lua")

dofile(cfg .. "windowrules.lua")

-- User extension point
local extra = os.getenv("HOME") .. "/.config/dotfiles/extra-bindings.lua"
if io.open(extra, "r") then pcall(dofile, extra) end
```

**Note**: `theme` variable must be global or passed to `general.lua` — use a global module pattern.

### Phase 3: Config Modules

Convert in this order (least risk first):

1. **`environment.lua`**: Mechanical; 14 `hl.env("VAR", "value")` calls.

2. **`monitor.lua.tmpl`**: Go template retained, syntax changes:
   ```lua
   hl.monitor({ output = "DP-1", mode = "3840x2160@144", position = "0x0", scale = 1.25 })
   hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "3072x144", scale = 1, transform = 1 })
   ```

3. **`autostart.lua`**: All `exec-once` become `hl.exec_cmd()` inside a single startup handler:
   ```lua
   hl.on("hyprland.start", function()
       hl.exec_cmd("waybar")
       hl.exec_cmd("awww-daemon")
       -- ...
   end)
   ```
   Sleep-prefixed commands: `os.execute("sleep 5") ; hl.exec_cmd(...)` or use `hl.timer()` if available.

4. **`input.lua`**: Direct `hl.config({ input = {...} })`.

5. **`general.lua`**: Reads `theme.activeBorder` / `theme.inactiveBorder` — needs the theme module loaded first. Use a global `_theme` table set in `hyprland.lua.tmpl`:
   ```lua
   -- In hyprland.lua.tmpl, after loading theme:
   _theme = dofile(os.getenv("HOME") .. "/.config/themes/current/hyprland.lua")
   ```
   Then in `general.lua`:
   ```lua
   hl.config({
       general = {
           gaps_in = 4, gaps_out = 8, border_size = 2,
           layout = "dwindle",
           col = { active_border = _theme.activeBorder, inactive_border = _theme.inactiveBorder }
       },
       dwindle = { preserve_split = true }
   })
   ```

6. **`decoration.lua`**: `hl.config({ decoration = { ... } })` with nested `blur` and `shadow`.

7. **`animations.lua`**: `hl.curve()` + `hl.animation()` calls.

8. **`plugins.lua`**:
   ```lua
   local hs = require("hyprsplit")
   hs.config({ num_workspaces = 10, persistent_workspaces = false })
   ```

### Phase 4: Window Rules

**`windowrules.lua`**: Convert each `windowrule =` line to `hl.window_rule({...})`.

Key syntax changes:
- `float on` → `float = true`
- `center 1` → `center = true`
- `size W H` → `size = {W, H}` (or string form `"W H"` — verify)
- `opacity V1 V2` → `opacity = "V1 V2"`
- `stay_focused on` → `stay_focused = true`
- `pin on` → `pin = true`
- Compound match: `match:class X, match:title Y` → `match = { class = "X", title = "Y" }`

**Layer rules**: `layerrule =` syntax for Lua is undocumented as of writing — check wiki when migrating. Keep as `hyprctl keyword layerrule` fallback if needed.

Example:
```lua
hl.window_rule({ match = { class = "pavucontrol" }, float = true })
hl.window_rule({ match = { class = "ai-scratchpad" }, float = true, center = true, size = "55% 65%" })
```

### Phase 5: Keybindings

Convert all 11 binding files. Mechanical but high-volume.

**`focus-navigation.lua`**: Arrow + vim keys with `hl.dsp.focus({ direction })` and `hl.dsp.window.move({ direction })`.

**`window-management.lua`**: `close`, `float`, `fullscreen`, `togglespecialworkspace`, `movetoworkspace`.

**`window-resizing.lua`**: `hl.dsp.window.resize()` + mouse binds with `{ mouse = true }` flag.

**`workspace-management.lua`**: Replace all `split:*` with `hs.*` dispatchers. Load hyprsplit module at top of file:
```lua
local hs = require("hyprsplit")
```

**`applications.lua.tmpl`**: Go template retained; `bindd` → `hl.bind` with `{ description = "..." }`.

**`voice.lua`**: Contains `bindr` (release trigger) → `{ release = true }` flag.

### Phase 6: Extension Points

**`voxtype-submap.lua`** (`conf.d/`):
```lua
hl.define_submap("voxtype_recording", function()
    hl.bind("F12", hl.dsp.exec_cmd("voxtype record cancel"))
    hl.bind("F12", hl.dsp.submap("reset"))
    hl.bind("SUPER + T",       hl.dsp.exec_cmd("voxtype record stop"), { release = true })
    hl.bind("SUPER SHIFT + T", hl.dsp.exec_cmd("voxtype record stop"), { release = true })
    hl.bind("SUPER CTRL + T",  hl.dsp.exec_cmd("voxtype record stop"), { release = true })
end)
```

**`extra-bindings.lua`** (user extension point in `dotfiles/`):
- Change chezmoi-managed stub from `.conf` to `.lua`
- Update `dotfiles-bindings-edit` script to reference `.lua` file
- The `hyprland.lua.tmpl` already wraps it in `pcall` (graceful on empty/error)

### Phase 7: Validation & Cleanup

1. Boot with `hyprland.lua` present; confirm it loads (not the old `.conf`)
2. Test all 80 keybindings
3. Verify all window rules apply correctly
4. Test theme switching (`theme switch catppuccin-latte`, etc.) — confirm border colors update
5. Test voxtype submap activation
6. Test `extra-bindings.lua` extension point
7. Reload with `Super+Shift+R`; confirm no errors in `hyprctl notify` / logs
8. Remove all `.conf` files except `hypridle.conf` and `hyprlock.conf`
9. Update `hypr/CLAUDE.md` to reflect Lua structure

---

## Open Questions

| Question | Impact | Where to check |
|---|---|---|
| `layerrule` Lua syntax | `windowrules.lua` (wofi blur rule) | Wiki update, or `hyprctl keyword layerrule` as fallback |
| `workspace, e+1` in `hl.dsp.focus()` | `workspace-management.lua` | Test at migration time |
| `movecurrentworkspacetomonitor` Lua API | `workspace-management.lua` | Wiki / hyprctl dispatch test |
| `hl.timer()` API for sleep-prefixed exec-once | `autostart.lua` | Wiki — may need `os.execute` workaround |
| `require("hyprsplit")` package.path | `plugins.lua` + binding files | hyprsplit install docs; may need explicit path |
| `binddr` (release + repeat) Lua equivalent | `voxtype-submap.lua` | Check if `{ release = true, repeating = true }` works |
| Global `_theme` across `dofile()` scope | `general.lua` | Lua global semantics — test pattern |

---

## Timeline Estimate

| Phase | Effort | Prerequisite |
|---|---|---|
| 0: Preparation | 30 min | — |
| 1: Theme extension | 1 hr | Phase 0 |
| 2: Main entry | 1 hr | Phase 1 |
| 3: Config modules | 2 hr | Phase 2 |
| 4: Window rules | 1 hr | Phase 2 |
| 5: Keybindings | 3 hr | Phase 3 |
| 6: Extension points | 1 hr | Phase 5 |
| 7: Validation | 2 hr | Phase 6 |
| **Total** | **~11 hr** | |

**Target**: Complete before Hyprland 0.57.
