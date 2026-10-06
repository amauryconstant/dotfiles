# hyprwhenthen — Window Event Automation

Reacts to Hyprland events (`windowtitlev2`, `openwindow`, …) to drive dynamic window behavior. Runs as the `hyprwhenthen.service` user unit (enabled by `run_once_after_002` from `.chezmoidata/services.yaml`). Upstream: https://github.com/fiffeek/hyprwhenthen

## Deployed config

- `config.toml` — handler definitions.
- `scripts/executable_float-and-center.sh` → `~/.config/hyprwhenthen/scripts/float-and-center.sh`.

🚨 **Lua dispatch form only.** Since the 2026-09-01 cutover Hyprland runs the Lua entry point,
where a legacy `dispatch togglefloating …` string is a hard error. Note also that
`hl.dsp.window.resize` takes **numbers** — there is no percent form — so `float-and-center.sh`
computes its 50% from `hyprctl monitors`, dividing by `.scale` first (that JSON is physical
pixels; window geometry is logical).

**The only handler** auto-floats and centers OAuth popups (Google/Microsoft/GitHub sign-in windows), matched on `windowtitlev2` and passed the window address via `$REGEX_GROUP_1`.

## Adding a handler

```toml
[[handler]]
on = "windowtitlev2"          # event type
when = "(.*),Picture-in-Picture"   # regex over event data; parens capture
then = "hyprctl dispatch 'hl.dsp.window.float({ window = \"address:0x$REGEX_GROUP_1\" })'"  # $REGEX_GROUP_N = capture N
```

Scripts referenced from `then` must be `executable_*` in `scripts/` (chezmoi sets the bit). Validate with `hyprwhenthen validate`; watch the event stream with `hyprwhenthen run --debug`.
