# Nextcloud Configuration

**Location**: `private_dot_config/Nextcloud/`
**Tool**: `chezmoi_modify_manager` — the repo's reference example of it. File: `modify_nextcloud.cfg.tmpl`.

## Why modify_manager here

The Nextcloud client writes settings **and** churning state (version strings, sync journal paths, proxy, cache) into one `nextcloud.cfg`. `modify_manager` keeps a managed output by filtering state and forcing user-specific values, so the file doesn't thrash on every sync.

**Mechanic** (non-obvious): the captured source state is `private_dot_config/Nextcloud/nextcloud.cfg.src.ini` — **in the chezmoi source dir**, next to the script, not in `~/.config/Nextcloud/`. `source auto` resolves it from `CHEZMOI_SOURCE_DIR` + `CHEZMOI_SOURCE_FILE`. The `.tmpl` script applies directives over that source (plus the live file on stdin) to produce `nextcloud.cfg`.

Re-adding is **`chezmoi_modify_manager --smart-add`**, *not* `chezmoi add` — that is when `add:remove` keys are stripped and `add:hide` keys masked, which is how host-specific values never enter git. Plain `chezmoi add` on this entry is *refused* rather than destructive (chezmoi will not overwrite a source template without `--force`), but it is still the wrong command.

**Ordering matters**: edit `ignore`/`add:remove` directives *before* re-adding. Ignored lines are not added back, so a re-add done first bakes the value into `.src.ini`.

## Directive reference

| Directive | Purpose |
|-----------|---------|
| `source auto` | locate the `.src.ini` |
| `ignore "Sect" "Key"` / `ignore section "Sect"` | drop a key / whole section |
| `ignore regex "Sect" "k1\|k2"` | drop keys by pattern (used for version/journal/proxy state) |
| `set "Sect" "Key" "val"` | force a value (templated) |
| `add:remove "Sect" "Key"` | pair with `set` — drop app-managed value from source on re-add |
| `add:hide "Sect" "Key"` | mask a secret in source — **not currently used here** (`authType=webflow`, so credentials live in the system keyring, not the cfg) |

The complete directive set is exactly eight: `source`, `ignore`, `set`, `remove`, `transform`, `add:remove`, `add:hide`, `no-warn-multiple-key-matches`. There is **no `ignore_order`** and **no `self_update`** directive — verify with `chezmoi_modify_manager --help-syntax`.

Rule of thumb: `ignore`/`ignore regex` for ephemeral state; `set`+`add:remove` for values that must be user-specific (paths, dav_user, displayName); `add:hide` for credentials.

## Repo-specific patterns (`modify_nextcloud.cfg.tmpl`)

- Filter churn: `ignore regex "General" "clientVersion|..."`, `ignore regex "Accounts" ".*version|.*journalPath|.*server.*|.*networkProxy.*"`.
- User identity/paths via `.firstname` (e.g. `set "Accounts" "0\\dav_user" "{{ .firstname | lower }}"` + matching `add:remove`).
- Server URL transform: `{{ $nextcloudServer := .privateServer | replace "www" "nextcloud" }}` → `set "Accounts" "0\\url"`.
- **`separator="=" ` on every `set`** — the directive defaults to `" = "`, but the client (QSettings) writes `key=value`. Without it the file never converges and reappears in `chezmoi status` on every client flush. This was the actual cause of the drift that fed `merge-all`. No global default exists; repeat it per `set`.

Preview before applying: `chezmoi cat ~/.config/Nextcloud/nextcloud.cfg`. Directive syntax: `chezmoi_modify_manager --help-syntax`.

**Never run `chezmoi merge`/`merge-all` on this entry** — it overwrites the generator with rendered INI. See `.claude/rules/chezmoi-modify-entries.md`. Quit the Nextcloud client before applying or re-adding; it rewrites the whole file from memory on quit.
