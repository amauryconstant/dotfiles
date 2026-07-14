# llama-swap Config - Claude Code Reference

**Location**: `private_dot_config/llama-swap/` → `~/.config/llama-swap/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **`config.yaml`**: llama-swap's native config — **plain file, NOT a template** (needs nothing from
  chezmoi data; `${env.HOME}` covers paths). Edit in-repo or via `chezmoi edit`.
- **Boundary**: this file is the *model configuration* (which GGUFs, per-role flags, groups) — user
  territory. The *backend/architecture* (host/port, unit, package) lives at chezmoi's level
  (`.chezmoidata/ai.yaml`, `systemd/user/llama-swap.service.tmpl`, `.chezmoidata/packages.yaml`).

## Structure

- `macros:` — reusable flag strings. `llama` carries the tuned chat flags (`--jinja -fa`, q8_0 KV
  cache, `--metrics`); `models_dir` is `${env.HOME}/.local/share/models`.
- `models:` — roles (`coder`/`helper`/`embed`). Chat roles use `${llama}`; `embed` does NOT (no
  `--jinja`; adds `--embedding --pooling`). Concrete models are **placeholder defaults** (final
  picks deferred — `_research/LOCAL_LLM_MODELS.md`).
- `groups:` — `resident` (helper + embed, `persistent: true`, ~4 GB always-on) and `heavy` (coder,
  swaps in/out with `ttl`). Group behavior is `swap`/`exclusive`/`persistent` + `members:` list.

## Non-obvious details

- **`# url:` convention**: llama-swap has no url field, so each model's download URL is a `# url:`
  comment above its `cmd`. Read by the `llama-models` CLI (`lib/scripts/ai/`), ignored by llama-swap.
  A `<...>` placeholder url = unset (not pulled).
- **Schema drift**: group/macro keys have changed across llama-swap versions. This config is pinned
  to the current documented schema (`members:` lists, `${env.HOME}`, `healthCheckTimeout`).
  Re-validate against the installed `llama-swap-bin` — llama-swap parses the config on start
  (`journalctl --user -u llama-swap`), and the `config-schema.json` modeline enables editor validation.
- **Env-var macros** use `${env.VAR}`, not shell `${VAR}` — llama-swap does its own substitution.

## Integration Points

- **CLI**: `llama-models` (`private_dot_local/lib/scripts/ai/CLAUDE.md`)
- **Service**: `llama-swap.service` listens on `.ai.server.{host,port}` (`systemd/user/CLAUDE.md`)
- **Models**: `~/.local/share/models` (populated by `llama-models pull`)
