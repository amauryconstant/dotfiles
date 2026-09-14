# Restic Offsite Backup — Implementation Plan

**Status**: Not started. Design complete, see `_research/RESTIC_REST_AUTHELIA_RESEARCH.md`
for the decisions behind each step below.
**Goal**: `home-backup` writes to a home-lab `rest-server`, behind SWAG + Authelia, instead
of a same-disk path — closes the reinstall-readiness blocker found 2026-09-14 (backup and
data currently die together on disk wipe).

---

## Phase 0 — Home-lab side (not chezmoi-managed, separate host)

Manual, on the home-lab box. Config already drafted in conversation; not written to this
repo since it targets a different machine's SWAG/Authelia install.

- [ ] `rest-server` container: `--append-only --no-auth --path /data`, on the SWAG/Authelia
      docker network only, no published ports.
- [ ] SWAG `proxy-confs/restic.subdomain.conf` — vhost for the backup subdomain.
- [ ] New nginx snippets `authelia-server-basic.conf` / `authelia-location-basic.conf` —
      **do not edit the existing browser-flow `authelia-location.conf`**, other services
      depend on it staying redirect-based.
- [ ] Authelia `configuration.yml` — add `auth-request/basic` authz endpoint
      (`HeaderAuthorization` strategy).
- [ ] Authelia `access_control.rules` — new rule, restic subdomain, `policy: one_factor`,
      placed above any catch-all rule.
- [ ] Authelia `users_database.yml` — dedicated `restic-backup` service account, argon2
      hash via `authelia crypto hash generate argon2`.
- [ ] Restart Authelia, reload SWAG nginx.
- [ ] Confirm the subdomain is reachable only via Tailscale/WireGuard, not port-forwarded.

## Phase 1 — Repo changes (this chezmoi tree)

- [ ] `.chezmoidata/packages.yaml`: add `libsecret` (provides `secret-tool`).
- [ ] `.chezmoidata/globals.yaml` under `globals.backup`: add `rest_host` and `rest_user`
      (non-secret — hostname and username only, no password).
- [ ] `private_dot_local/lib/scripts/system/executable_home-backup`:
  - Build `REPO` from `secret-tool lookup` + globals at runtime when `rest_host` is set and
    `RESTIC_REPOSITORY` isn't already overridden; fall back to today's local path otherwise.
  - Add `_repo_exists()` / `_repo_mkdir()` helpers that branch on `rest:`/`s3:`/`sftp:`/`b2:`
    prefix vs local path.
  - Swap the 5 call sites (`[[ -d "$REPO" ]]` at lines ~73, 104, 122; `mkdir -p "$REPO"` at
    lines ~109, 147) to use the helpers.
- [ ] Validate rendered script: `bash -n`, then `shellcheck`.

## Phase 2 — Credential seed (manual, one-time, not chezmoi-tracked)

- [ ] On the machine running `home-backup`:
      `secret-tool store --label="home-backup REST auth" service home-backup-rest username restic-backup`
      — paste the Authelia service-account password from Phase 0.
- [ ] Confirm lookup works: `secret-tool lookup service home-backup-rest username restic-backup`.

## Phase 3 — Validate

- [ ] `chezmoi apply` (picks up `libsecret` + `globals.yaml` changes).
- [ ] `restic -r "$REPO" init` against the new REST endpoint (or `home-backup init` once
      Phase 1 wires it through) — confirms Authelia auth + rest-server reachability end to
      end.
- [ ] `home-backup backup` — real snapshot, check `home-backup status` reflects it.
- [ ] Unset `rest_host` locally and confirm `home-backup` still falls back to the local path
      cleanly — the override must be additive, not a hard requirement, for machines without
      a home-lab target configured.
- [ ] Re-run the reinstall-readiness check: confirm the backup blocker from the 2026-09-14
      audit is closed.

---

## Explicitly out of scope

- No change to `.restic-password` handling — stays a local flat file, different threat
  model (see research doc §3).
- No age/Vaultwarden distribution of the Authelia credential — single-machine scope for now;
  revisit only if a second machine needs to back up to the same `rest-server`.
- No `rotate-age-key`-style rotation tooling for the new credential — add if/when rotation
  is actually needed, not speculatively.
