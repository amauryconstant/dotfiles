# AI Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/ai/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **UI pattern**: gum-ui (`ui_*`) — system CLI category
- **PATH**: `ai/` is registered in `zsh/dot_zstyles` (new categories must be added there)

## Scripts

| Script | CLI | Purpose | UI |
|--------|-----|---------|-----|
| `executable_llama-models` | `llama-models` | On-demand GGUF downloads + roster/status for the llama-swap backend | gum-ui |

## llama-models

On-demand model management for the local LLM backend. Reads the roster from
`~/.config/llama-swap/config.yaml` (source: `private_dot_config/llama-swap/config.yaml`) — it does
**not** download at `chezmoi apply` time (that automation was retired). Subcommands:

- `pull` — download GGUFs referenced by config but missing from `~/.local/share/models` (resumable
  `wget -c` → `.part` → atomic rename; skips present files and roles with no url).
- `list` — roster + on-disk presence per role.
- `status` — `llama-swap.service` active state + `/health` + `/running` models.

**`# url:` convention**: llama-swap's schema has no url field, so each model's download URL rides
as a `# url:` comment above its `cmd`. The CLI pairs that comment with the `--model` filename from
the same model block. A url of `<...>` (angle-bracket placeholder) means "unset" — not pulled
(e.g. the `embed` role, populated later by the RAG sub-project).

**Overrides** (env): `LLAMA_SWAP_CONFIG`, `LLAMA_MODELS_DIR`, `LLAMA_SWAP_HOST`/`LLAMA_SWAP_PORT`.

## Integration Points

- **Config**: `~/.config/llama-swap/config.yaml` (see `private_dot_config/llama-swap/CLAUDE.md`)
- **Service**: `llama-swap.service` (see `systemd/user/CLAUDE.md`)
- **Backend data**: `.chezmoidata/ai.yaml` (`ai.server.{host,port}` — the unit's `--listen`)
