# Local LLM CLI Helper Tools (+ Voice back-half)

**Status**: Research / decision input (2026-07-13)
**Scope**: Shell/CLI helper tools consuming the local llama-server (OpenAI-compat, 127.0.0.1:8080). Secondary: voice-assistant back-half (TTS).
**Context**: RTX 4090 24GB + i9-13900K, Arch, zsh (antidote), Hyprland + Wofi + gum menus. Backend already decided: llama.cpp / `llama-server` systemd user service. See [[local-llm-backend-decision]], `_research/LLM_BACKENDS_RESEARCH.md`.
**Related repo bits**: `private_dot_local/lib/scripts/user-interface/executable_menu-ai.tmpl` (existing menu-ai submenu), `.chezmoidata/ai.yaml` (server port/host/models), `.chezmoidata/packages.yaml` (AI/LLM group).

---

## Executive summary

**Primary pick: `aichat`** (sigoden, Rust). It is the single best fit for use-case #2 (unlimited/offline quick tasks) because it covers *all three* interaction modes we care about from one binary + one config file:

- **Pipe/filter**: `cmd | aichat 'summarize'` — stdin-aware, Markdown/syntax-highlighted output.
- **zsh ZLE widget**: ships an official Alt-E shell-integration script that rewrites the current buffer from natural language into a runnable command (edit-before-run, exactly the UX we want).
- **Interactive REPL + roles/macros/RAG + `--serve`** for heavier sessions.

Decisive advantage: **`aichat` is in the official Arch `extra` repo** (`pacman -S aichat`, currently 0.30.0) — no AUR, no Go/Python toolchain, no telemetry, single static binary. That aligns with the repo's supply-chain policy far better than the alternatives.

**Secondary pick: `simonw/llm` + `llm-llama-server` plugin** — as a *scriptable/composable* helper for our own `lib/scripts` wrappers and one-shot templated prompts (git commit messages, rename/summarize). Its plugin/templates/logging model and Python-library form make it the better "glue" tool for programmatic use where `aichat` is the better "interactive" tool. Only adopt if we actually want programmatic prompting beyond what `aichat -m`/roles already give us — otherwise `aichat` alone suffices.

**Dropped / not recommended now**: `mods` (**archived March 2026** — dead end); `crush` and `aider`/`gptme` (coding *agents*, overlap with the already-chosen `opencode`/`claude-code`, overkill for "quick shell tasks"); `fabric` (Go, AUR-only, heavier prompt-framework — revisit only if we want its crowdsourced pattern library); `shell_gpt`/`zsh_codex`/`zsh-ai` (narrower single-purpose widgets that `aichat`'s shell integration already subsumes).

**Voice back-half: NO-GO (for now).** Voxtype already does STT→text well. Adding LLM→TTS→loop is a genuinely separate project (wake-word/turn-taking, barge-in, TTS model, audio routing) with low payoff on a keyboard-first Hyprland desktop. If ever revisited, use **Kokoro-82M** (Apache-2.0, ~5x realtime on CPU, GPU-trivial on the 4090) as the TTS. Minimal sketch included below, but recommend shelving it.

---

## Assumptions challenged

1. **"We need a shell tool AND a zsh widget AND a pipe filter."** — False as three tools. `aichat` is all three. Adding `sgpt`/`zsh_codex` on top would be redundant surface area.
2. **`mods` is a live option.** — No. Archived 2026-03-09, read-only; Charm points users to `crush`. Any doc/tutorial recommending `mods` is now stale. Don't build on it.
3. **A CLI helper and a coding agent are the same slot.** — No. Use-case #2 (quick, unlimited, offline shell chores with a *small fast* model) is distinct from use-case #1 (coding assistant, already served by `opencode`/`claude-code` in `menu-ai`). Conflating them pulls in heavyweight agents (crush/aider/gptme) that we don't need for "explain this command."
4. **Everything should be a Wofi menu entry.** — Partly. The high-value integration is the **zsh ZLE widget** (in-terminal, where shell work happens), not a menu. `menu-ai` stays for launching sessions/status; the quick-helper lives at the prompt.
5. **We must pick a coding agent here.** — Out of scope; already decided elsewhere. This doc is deliberately about the *lightweight helper* layer.
6. **Local model choice is settled.** — It is NOT (`.chezmoidata/ai.yaml` `models: []`). The helper UX assumes a small fast instruct model is loaded (e.g. Qwen2.5/3 3B–7B instruct GGUF) for snappy command-gen; the big coder model is for use-case #1. This may argue for two `llama-server` profiles or an on-demand small model — an open question below.

---

## Part A: Shell/CLI tools landscape & tradeoff table

Legend: ✅ strong · 🟡 partial/workable · ❌ weak/absent

| Tool | Lang / pkg on Arch | Local OpenAI-compat config | Pipe / filter | zsh ZLE widget (cmd-gen) | Interactive | Config format | Theming | Telemetry | Fit for use-case #2 |
|------|--------------------|----------------------------|---------------|--------------------------|-------------|---------------|---------|-----------|---------------------|
| **aichat** | Rust · **`extra/aichat`** (official) | ✅ `clients: [{type: openai-compatible, api_base: http://127.0.0.1:8080/v1}]` | ✅ stdin-aware, MD render | ✅ official Alt-E buffer-rewrite script (bash/zsh/fish/nu) | ✅ REPL, roles, macros, RAG, `--serve` | single `config.yaml` | ✅ syntax-highlight themes (`.tmTheme`) | ✅ none | **Best — all modes, official pkg** |
| **llm** (simonw) | Python · AUR (`python-llm`) or `uv`/pipx | ✅ `llm-llama-server` plugin OR `extra-openai-models.yaml` | ✅ `... | llm -s` | 🟡 no official widget; scriptable into one | ✅ templates, logging (SQLite), plugins | YAML + SQLite log | 🟡 plain text | **Best for scripting/glue** |
| **fabric** | Go · AUR (`fabric-ai`) | ✅ `openai_compatible` provider / setup wizard | ✅ pattern piping (`-p`) | 🟡 via `-p` + shell fn, no native widget | 🟡 pattern-runner, `--serve` | env/YAML + patterns dir | 🟡 | 🟡 | Good if we want its pattern library; heavier |
| **mods** | Go · AUR | ✅ (LocalAI :8080 default) | ✅ | ❌ completions only | 🟡 | YAML | ✅ 4 themes | ✅ | ❌ **ARCHIVED 2026-03** — avoid |
| **crush** | Go · AUR (`crush`) | ✅ `type: openai-compat`, base_url | 🟡 (agent, not filter) | ❌ | ✅ full TUI agent | JSON | ✅ glamour | 🟡 | ❌ coding-agent overlap w/ opencode |
| **aider** | Python · AUR | ✅ `openai/<model>` + `OPENAI_API_BASE` | 🟡 `--message`, `--yes` | ❌ | ✅ pair-programming | yaml/env | 🟡 | 🟡 | ❌ git-coding agent, overkill for chores |
| **gptme** | Python · AUR/pipx | ✅ llama.cpp provider | 🟡 stdin→agent | ❌ | ✅ tool-using agent | env/toml | 🟡 | 🟡 | ❌ agent, heavier than needed |
| **shell_gpt** (`sgpt`) | Python · AUR (`shell-gpt`) | ✅ `API_BASE_URL` + `DEFAULT_MODEL` | ✅ stdin | ✅ Ctrl-based buffer integration | 🟡 `--repl` | `~/.config/shell_gpt/.sgptrc` (env-style) | ❌ | 🟡 | 🟡 works but subsumed by aichat |
| **zsh_codex** | zsh+Python · AUR/manual | ✅ Ollama/openai-compat service block | n/a | ✅ Ctrl-X Ctrl-A completion | ❌ | `~/.config/zsh_codex.ini` | ❌ | ✅ | 🟡 widget-only; aichat covers it |
| **zsh-ai** | pure zsh · manual (git plugin) | ✅ env `OPENAI_BASE_URL` (llama.cpp supported) | n/a | ✅ `# nl` → command, zero deps | ❌ | env vars | ❌ | ✅ | 🟡 minimal; nice fallback, but less capable |

**Notes on the front-runners**

- **aichat local config** (`~/.config/aichat/config.yaml`) — canonical shape for llama-server:
  ```yaml
  model: llama-server:local           # <client>:<model-id>
  clients:
    - type: openai-compatible
      name: llama-server
      api_base: http://127.0.0.1:8080/v1
      models:
        - name: local                 # matches --served-model-name / any id llama-server reports
  ```
  Shell command-gen role is built in (`-r %shell%` / `-e`), which the Alt-E widget uses. Shell-integration scripts: `github.com/sigoden/aichat/tree/main/scripts/shell-integration`.
- **aichat Alt-E widget** (zsh) — type natural language, press Alt-E, buffer is replaced by the command for edit-before-run:
  ```zsh
  _aichat_zsh() {
    if [[ -n "$BUFFER" ]]; then
      local _old=$BUFFER
      BUFFER+="⌛"; zle -I && zle redisplay
      BUFFER=$(command aichat -e "$_old")
      zle end-of-line
    fi
  }
  zle -N _aichat_zsh
  bindkey '\ee' _aichat_zsh    # Alt-E
  ```
- **llm local config** — either the plugin (`llm install llm-llama-server`; requires llama-server on :8080) or a plain `extra-openai-models.yaml` pointing `api_base` at `http://127.0.0.1:8080/v1`. Strength is *composition*: `llm -t <template>`, `-s system`, SQLite-logged, importable as a Python lib — ideal for our `lib/scripts` wrappers (commit messages, summaries) and reproducible prompt templates.

---

## Recommended CLI tooling (which tool for which job) + zsh/menu integration sketch

**Adopt `aichat` as the primary helper.** Job map:

| Job | Tool + invocation | Where it lives |
|-----|-------------------|----------------|
| NL → shell command (edit before run) | `aichat -e` via **Alt-E ZLE widget** | zsh widget (in-terminal) |
| Pipe filter (summarize/explain/reformat stdout, logs, diffs) | `… | aichat '<instruction>'` | shell pipeline; optional `aihelp` fn |
| Explain a command / quick Q&A | `aichat 'explain: <cmd>'` or REPL | shell fn + `menu-ai` REPL entry |
| Interactive session | `aichat` (REPL) | new `menu-ai` entry (ghostty `--class ai-scratchpad`) |
| Programmatic/templated prompts (commit msgs, batch rename, summarize files) | `llm -t <template>` (secondary) | `lib/scripts` (e.g. feed the `commit` skill / git hooks) |

**zsh integration** (fits antidote + `.zstyles` env pattern):
- Add the Alt-E widget above to a sourced zsh file (e.g. a new `private_dot_config/zsh/` fragment or the aichat integration script). Keybinding `Alt-E` avoids clashing with existing binds — verify against `private_dot_config/hypr/conf/bindings/` and zsh widgets first.
- Optional convenience functions: `ai() { aichat "$@"; }`, `explain() { aichat -r %shell% "explain: $*"; }`, `aipipe` for the filter case. Keep them thin; the widget is the star.
- Point `aichat` at the same host/port already in `.chezmoidata/ai.yaml` — template the `api_base` so port stays single-source (`{{ .ai.server.host }}:{{ .ai.server.port }}`).

**menu-ai expansion** (`executable_menu-ai.tmpl`): add entries alongside opencode/claude-code/status:
- `󰭹 aichat REPL` → `{{ .globals.applications.terminal }} --class ai-scratchpad -e aichat`
- (optional) `󰘳 NL→command` hint entry that just notifies the Alt-E keybinding, since command-gen belongs at the prompt, not a menu.

**Theming**: `aichat` supports syntax-highlight themes (`.tmTheme`). Wire a `theme-apply-aichat` into the existing `theme-apply-*` family (`lib/scripts/desktop/`) that symlinks/generates a theme from `~/.config/themes/current/` semantic vars — same pattern as `theme-apply-opencode`. Low priority; the REPL is legible with defaults.

---

## Part B: Voice back-half (TTS options, go/no-go)

We already have **Voxtype** (STT→text: dictation/transliteration). A true voice *assistant* adds: STT → **LLM** (have it) → **TTS** (missing) → an interaction **loop** (wake/turn-taking, barge-in, audio routing) — plus the dead `meeting.summary` ollama ref noted in the backend memo still needs repointing/removal.

**Local TTS options (2026):**

| Engine | Quality | Speed | License | Footprint | Notes |
|--------|---------|-------|---------|-----------|-------|
| **Kokoro-82M** | Near-XTTS on fixed voices; "sounds human" | ~5x realtime CPU; trivial on 4090 | Apache-2.0 | ~327 MB weights, ~2–3 GB VRAM | **Best default** — 54 voices/8 langs |
| **Piper** | Good but audibly synthetic | ~30x realtime CPU, RPi-capable | GPL-3.0 (active fork `OHF-Voice/piper1-gpl`; old rhasspy MIT archived Oct 2025) | few hundred MB | Minimalist CPU fallback |
| **XTTS/Coqui** | High + voice-clone | Slower, GPU-favored | Coqui license (project defunct) | large | Overkill; maintenance risk |
| **Parler-TTS** | Good, promptable | GPU | Apache-2.0 | large | Research-y; unnecessary here |

**Recommendation: NO-GO (shelve).** Rationale: keyboard-first Hyprland workflow; the hard part is the *loop* (VAD/turn-taking/barge-in/interrupt handling), not the models; high build+maintenance cost for marginal daily value; competes for attention with actually-pending work (pick the model, opencode local provider, shell helper — this doc). Voxtype already delivers the high-value voice feature (dictation).

**If ever revisited — minimal sketch only** (a `lib/scripts/desktop/voice-assistant` loop, push-to-talk keybind, no wake word):
```
[Super+hold] → record → voxtype STT → text
   → aichat/llm (small model, :8080)          # reuse the same helper backend
   → Kokoro (kokoro-onnx, CUDA) → aplay/pw-play
   → notify-send transcript; Esc/keyup to barge-in
```
Keep it push-to-talk (no always-listening), reuse the aichat/llm backend already stood up for Part A, and gate behind a `features.yaml` toggle like the existing `features.voxtype`. Do not build until Part A is in daily use.

---

## Open questions

1. **Which small model for the helper?** Command-gen wants a snappy 3B–7B instruct (e.g. Qwen2.5-Coder-3B / Qwen3-4B instruct GGUF), *not* the 30B coder. Do we run a second `llama-server` profile/port for the small model, swap models on demand, or accept one shared model? Affects `.chezmoidata/ai.yaml` (`models:` still `[]`) and how `aichat` `api_base`/model id are templated.
2. **Two ports or one?** If a dedicated small-model server, add a second systemd user service + port; else `aichat` and opencode share `:8080` and whatever model is loaded.
3. **`llm` — adopt now or defer?** Only pull it in if we want programmatic/templated prompting (commit-message generation via the `commit` skill, batch summarize). Otherwise `aichat` roles cover it and we avoid a Python dep.
4. **Keybinding collisions**: confirm `Alt-E` (or chosen chord) is free across zsh ZLE + Hyprland binds before wiring the widget.
5. **Commit-message helper**: worth a dedicated `lib/scripts/git` wrapper (or git prepare-commit-msg hook) using the local model + the repo's `commit` skill conventions? Natural first "real" use of the helper.

---

## Dotfiles integration notes

- **Packages** (`.chezmoidata/packages.yaml`, AI/LLM group ~line 249): add `aichat` (official `extra` — pacman, no AUR/toolchain, no telemetry → clean supply-chain fit). Defer `python-llm`/`llm` until Q3 above is answered. Do **not** add `mods` (archived).
- **ai.yaml** (`.chezmoidata/ai.yaml`): finally populate `models:` (blocks the whole helper). Template `aichat` `api_base` from `.ai.server.host`/`.ai.server.port` so the port is single-source.
- **zsh widget**: new sourced fragment under `private_dot_config/zsh/` (antidote-loaded) with the Alt-E `_aichat_zsh` widget + thin `ai`/`explain`/`aipipe` functions. Env via `.zstyles` if needed.
- **aichat config**: `private_dot_config/aichat/config.yaml.tmpl` (or `private_aichat/`), rendered with host/port + default role. Keep secrets out (local endpoint, none needed).
- **menu-ai** (`executable_menu-ai.tmpl`): add `aichat REPL` entry (`--class ai-scratchpad -e aichat`), mirroring existing opencode/claude-code entries. Icons via `/nerdfonts-search` (prefer `md-`/`cod-`).
- **Theming**: optional `theme-apply-aichat` in `lib/scripts/desktop/` following `theme-apply-opencode` pattern (semantic vars → `.tmTheme`); register in the theme-switcher's `theme-apply-*` chain.
- **Voice**: no dotfiles changes now; if pursued later, gate under `.chezmoidata/features.yaml` like `features.voxtype`, and repoint/remove Voxtype's dead `meeting.summary` ollama reference regardless (already flagged in backend memo).

---

## Sources

- mods (archived 2026-03) — https://github.com/charmbracelet/mods · https://github.com/charmbracelet/mods/blob/main/README.md
- crush (mods successor) — https://github.com/charmbracelet/crush · https://github.com/charmbracelet/crush/discussions/775
- aichat — https://github.com/sigoden/aichat · Config Guide https://github.com/sigoden/aichat/wiki/Configuration-Guide · Command-Line Guide https://github.com/sigoden/aichat/wiki/Command-Line-Guide · shell-integration https://github.com/sigoden/aichat/tree/main/scripts/shell-integration
- aichat Arch packaging — https://archlinux.org/packages/extra/x86_64/aichat/ · https://repology.org/project/aichat/packages
- simonw/llm — https://github.com/simonw/llm · llm-llama-server plugin https://github.com/simonw/llm-llama-server · https://simonwillison.net/2024/Jun/17/cli-language-models/
- fabric — https://github.com/danielmiessler/fabric · AUR https://aur.archlinux.org/packages/fabric-ai
- shell_gpt — https://github.com/ther1d/shell_gpt · AUR https://aur.archlinux.org/packages/shell-gpt
- zsh_codex — https://github.com/tom-doerr/zsh_codex
- zsh-ai — https://github.com/matheusml/zsh-ai
- gptme — https://gptme.org/ · https://gptme.org/docs/providers.html
- aider (OpenAI-compat) — https://aider.chat/docs/llms/openai-compat.html
- llama.cpp offline agentic tutorial — https://github.com/ggml-org/llama.cpp/discussions/14758
- TTS comparisons — https://contracollective.com/blog/kokoro-vs-piper-vs-xtts-local-text-to-speech-m5-max-2026 · https://localaimaster.com/blog/best-local-tts-models · https://www.codesota.com/text-to-speech · Piper GPL fork https://github.com/OHF-Voice/piper1-gpl
