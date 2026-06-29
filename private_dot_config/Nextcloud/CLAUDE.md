# Nextcloud Configuration

**Location**: `private_dot_config/Nextcloud/`
**Tool**: `chezmoi_modify_manager` — the repo's reference example of it. File: `modify_nextcloud.cfg.tmpl`.

## Why modify_manager here

The Nextcloud client writes settings **and** churning state (version strings, sync journal paths, proxy, cache) into one `nextcloud.cfg`. `modify_manager` keeps a managed output by filtering state and forcing user-specific values, so the file doesn't thrash on every sync.

**Mechanic** (non-obvious): the live file is captured as `~/.config/Nextcloud/nextcloud.cfg.src.ini` (`source auto` finds it); the `.tmpl` script applies directives over that source to produce `nextcloud.cfg`. On `chezmoi add`, `add:remove` keys are stripped from the source and `add:hide` keys are masked — that's how secrets/host-specific values never enter git.

## Directive reference

| Directive | Purpose |
|-----------|---------|
| `source auto` | locate the `.src.ini` |
| `ignore "Sect" "Key"` / `ignore section "Sect"` | drop a key / whole section |
| `ignore regex "Sect" "k1\|k2"` | drop keys by pattern (used for version/journal/proxy state) |
| `set "Sect" "Key" "val"` | force a value (templated) |
| `add:remove "Sect" "Key"` | pair with `set` — drop app-managed value from source on re-add |
| `add:hide "Sect" "Key"` | mask a secret (e.g. `0\\password`) in source |
| `ignore_order` / `self_update enable` | list-order tolerance / driver self-update |

Rule of thumb: `ignore`/`ignore regex` for ephemeral state; `set`+`add:remove` for values that must be user-specific (paths, dav_user, displayName); `add:hide` for credentials.

## Repo-specific patterns (`modify_nextcloud.cfg.tmpl`)

- Filter churn: `ignore regex "General" "clientVersion|..."`, `ignore regex "Accounts" ".*version|.*journalPath|.*server.*|.*networkProxy.*"`.
- User identity/paths via `.firstname` (e.g. `set "Accounts" "0\\dav_user" "{{ .firstname | lower }}"` + matching `add:remove`).
- Server URL transform: `{{ $nextcloudServer := .privateServer | replace "www" "nextcloud" }}` → `set "Accounts" "0\\url"`.

Preview before applying: `chezmoi cat ~/.config/Nextcloud/nextcloud.cfg`. Directive syntax: `chezmoi_modify_manager --help-syntax`.
