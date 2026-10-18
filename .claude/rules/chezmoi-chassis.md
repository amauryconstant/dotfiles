---
paths:
  - "**/*.tmpl"
  - ".chezmoiignore"
  - ".chezmoidata/**"
---

# Laptop / Desktop Gating

`.chassisType` (`laptop` | `desktop`) is computed in `.chezmoi.yaml.tmpl`. Everything that differs
between the two machines hangs off it, and **only this machine's branch is ever rendered or linted**.

## Where the condition belongs

| Site | Pattern |
|---|---|
| A whole file differs | `.chezmoiignore`: `{{ if ne .chassisType "laptop" }}` + the target path (steam.desktop, the Bluetooth wireplumber drop-in) |
| A block inside a file | `{{ if eq .chassisType "laptop" }}` in the `*.tmpl` (`hypr/conf/monitor.lua.tmpl`, `bindings/hardware.lua.tmpl`) |
| A script runs on one machine | gate in the `.chezmoiscripts/` template (`configure_kanata`, `configure_voxtype`) |
| QML | **one value**, `Config.isLaptop` in `Config.qml.tmpl`, consumed by `visible:` — never a second template or a branch in the template layer |
| Profile lists (Firefox) | filtered in the `firefox_profiles` include, not in `firefox.yaml` |

🚨 **Never in `.chezmoidata/*.yaml`.** Data files are inert: `{{ eq .chassisType "laptop" }}` inside one
is emitted as the literal string (`chezmoi-data.md`). Data states facts (`chassis: [laptop]`); the
consumer decides.

## Rendering the OTHER branch

`mise run lint` renders only the current machine's branch, so a gated block is invisible to it.
Flip the data instead of guessing — verified on `monitor.lua.tmpl` and `Config.qml.tmpl` (output
differs; `isLaptop: true` / `false`):

```bash
for c in laptop desktop; do
  chezmoi execute-template --source "$PWD" --override-data "{\"chassisType\":\"$c\"}" \
    < path/to/file.tmpl | stylua --check --stdin-filepath file.lua -   # or: luajit -bl -, shellcheck -
done
```

`--source "$PWD"` is load-bearing (worktrees render the global tree otherwise). For a `.chezmoiignore`
change, render it the same way and read which paths survive.

Edited a gated block? Render **both** values and lint both outputs before committing.
