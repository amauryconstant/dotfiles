# WirePlumber Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/wireplumber/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: PipeWire session policy — the only audio *policy* this repo owns
- **File**: `wireplumber.conf.d/50-audio-defaults.conf` (drop-in; merged alphabetically over `/usr/share/wireplumber/wireplumber.conf`)
- **Format**: SPA-JSON, not Lua. WirePlumber 0.5 moved settings into `wireplumber.settings`
- **Templates**: `/usr/share/doc/wireplumber/examples/wireplumber.conf.d/*.conf` — the authoritative key list, shipped with the package
- **Verify a key exists**: `grep -n '<key>' /usr/share/wireplumber/wireplumber.conf` (the schema block at ~:948 carries every settable name, its type and its default)

## 🚨 A2DP has no microphone

`bluetooth.autoswitch-to-headset-profile` defaults **true**, and its own description is
*"Always show microphone for Bluetooth headsets, and switch to headset mode when recording"*.
So a phantom `bluez_input` source appears for any connected headset, WirePlumber makes it the
default source by priority, and the next capture open drags the card from A2DP to HFP.

On this laptop (Intel AX200 + Sony WH-1000XM4) that SCO transport fails:

```
spa.bluez5: Failure in Bluetooth audio transport /org/bluez/hci0/dev_F8_4E_17_6F_6E_93/fd72
pw.node: (bluez_input...)  suspended -> error
pw.node: (bluez_output...) running   -> error
```

Both directions die, so the symptom is **two** unrelated-looking bugs at once: dictation
captures digital silence (`pw-record` gives `rms 0.0, peak 0`), and whatever was playing stops
for good, because the sink it was attached to no longer exists. voxtype's `pause_media` then
has nothing to resume onto, which reads as "voxtype broke Spotify".

The drop-in turns the autoswitch off. The headset stops advertising a mic at all, so nothing
can reach for HFP and playback stays on LDAC.

**Escalation if a phantom source ever survives**: trim the roles instead —
`monitor.bluez.properties { bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source ] }`.
That removes the headset profile outright, including for deliberate use. Not set today.

**Worth knowing**: the XM4 mic is HFP-only, 16 kHz mono, and using it downgrades playback to
headset quality for the duration. The built-in mic is the better dictation source even when
Bluetooth capture works.

## State outlives config

`~/.local/state/wireplumber/` is written by WirePlumber, not by chezmoi, and survives any
change here:

| File | Holds |
|---|---|
| `bluetooth-autoswitch` | `saved-headset-profile:<card>=headset-head-unit` — a remembered HFP switch |
| `default-nodes` | `default.configured.audio.{sink,source}` — what `wpctl set-default` persisted |
| `default-routes` | per-device port + volume |
| `stream-properties` | per-app volume |

After first applying this drop-in, clear the remembered headset profile once:

```bash
rm -f ~/.local/state/wireplumber/bluetooth-autoswitch
systemctl --user restart wireplumber
```

## Diagnosing

```bash
wpctl status                                   # Sources/Filters: no bluez_input is the goal
pactl get-default-source                       # should stay alsa_input.pci-*
pactl list cards | grep -A2 'Active Profile'   # bluez_card must read a2dp-sink
journalctl --user -u wireplumber -f            # watch while dictating
timeout 3 pw-record --target @DEFAULT_AUDIO_SOURCE@ /tmp/mic.wav   # then check the level
```

A resume-time sweep already exists and is unrelated to this: `.chezmoitemplates/hypridle_general`
restarts wireplumber in `after_sleep_cmd` to clear orphaned sink nodes — see
`.claude/rules/quickshell-qml.md` for why that leak matters to the bar.

## Integration Points

- **Mic mute**: `~/.local/lib/scripts/desktop/mic-mute` (wpctl + ThinkPad `platform::micmute` LED), bound to `XF86AudioMicMute`
- **Sink switching**: `~/.local/lib/scripts/desktop/audio-switch` (`wpctl set-default`, persists)
- **Bar**: Quickshell `AudioWidget` (sink) and `MicrophoneWidget` (source muted)
- **Dictation**: `private_dot_config/voxtype/config.toml.tmpl` `[audio] device = "default"` relies on this file
