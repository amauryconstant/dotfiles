# Firefox Multi-Profile (Classic Declarative) Implementation Plan

> **Status (2026-10-10): NOT EXECUTED.** Nothing in Tasks 1–7 has been run. The plan was drafted July–August against Firefox 153; it was reconciled with the live machine and repo on 2026-10-10 (Firefox now **157.0.1**). Changes made in that pass: Task 2 retargeted from `hypr/conf/environment.{conf,lua}` (now an empty stub) to `uwsm/env.tmpl`; Task 2 Step 4 (throwaway-`$HOME` picker test) is a hard gate and must pass on 157 before Task 3; Task 3 sizes and the `profiles.ini` claim corrected (585 MB / 320 MB; Work now has an INI entry, names still come only from sqlite); Task 4 launchers route through the EGL wrapper. Still true and unchanged: `~/.config/mozilla/firefox/` holds only `Crash Reports/`, `theme-apply-firefox` is dead for the same reason, `1cevmaad.default` still exists.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage three Firefox profiles (`work`, `leisure`, `ringstone`) declaratively from a single chezmoi data file, targeting Firefox's XDG profile location, with per-profile `user.js`, a generated `profiles.ini`, per-profile theme `userChrome.css`, and per-profile `.desktop` launchers.

**Architecture:** A new `.chezmoidata/firefox.yaml` is the single source of truth. A hash-triggered `run_onchange` chezmoi-template script ranges over that data to create each profile directory under `~/.config/mozilla/firefox/`, write its `user.js`, generate a classic `profiles.ini`, and emit per-profile launchers. The existing `theme-apply-firefox` script is retargeted to XDG and loops over every managed profile. Firefox's new SQLite-backed profile selector (`SelectableProfileService`) is deliberately disabled (`browser.profiles.enabled=false`) so all profile identity lives in the declarative `profiles.ini` — not a browser-owned, version-unstable database. Firefox's *per-install dedicated profile* mechanism is likewise disabled session-wide (`MOZ_LEGACY_PROFILES=1`); this is what makes the classic Profile Manager reachable at all (see the constraint below). A separate one-time migration helper carries the existing `Work`/`Perso` data into the new `work`/`leisure` directories.

**Selection model:** `StartWithLastProfile=0`. A plain `firefox` with no arguments shows the classic Profile Manager every time; `Default=1` marks which entry it preselects. Deliberate launches bypass the picker entirely via `firefox -P <id>` or the generated per-profile `.desktop` launchers. The split is: **launchers for intent, picker for "I didn't say."**

**Tech Stack:** chezmoi (Go text/template + Sprig), POSIX sh + Bash, Firefox 147+ (XDG base-dir support), sqlite3 (migration only).

## Global Constraints

- **XDG target path:** `~/.config/mozilla/firefox/` — both `profiles.ini` **and** the profile directories live here (verified empirically on Firefox 153.0.1; `XDG_DATA_HOME` is *not* used for profiles).
- **`~/.config/mozilla/firefox/` already exists on this machine** (created Nov 2025, contains only `Crash Reports/` — no `profiles.ini`, no profile dirs). It is benign, but it is the reason `theme-apply-firefox` is currently dead: that script's XDG-first branch already matches today, finds no `*.default-release` underneath, and exits 0. It has been silently doing nothing since November. Any script that picks a Firefox root by directory existence must account for this.
- **Legacy takes precedence over XDG, and the trigger is `~/.mozilla/firefox` — not `~/.mozilla`.** Verified: an empty `~/.mozilla` still yields XDG; creating `~/.mozilla/firefox` flips Firefox back to legacy. So removing the `firefox` subdirectory alone is sufficient, and `~/.mozilla/extensions` can be left in place.
- **`MOZ_LEGACY_PROFILES=1` is mandatory — and its purpose is broader than `Default=1`.** Without it Firefox applies per-install dedicated profiles: it *auto-creates* its own `*.default-release`, *auto-binds* it via an `[Install<HASH>]` section, writes `installs.ini`, and leaves the managed profiles unused. That bypasses `Default=1` and the Profile Manager alike — an automatic selection means the picker never appears. The variable is therefore what makes "no automatic selection → show the classic Profile Manager" reachable at all, not merely what makes `Default=1` authoritative. Verified both ways on Firefox 153.0.1.
- **Every launch path goes through the EGL wrapper.** `~/.local/bin/firefox` (`private_dot_local/bin/executable_firefox`) is mandatory on this NVIDIA machine: bare `/usr/lib/firefox/firefox` starts but never maps a window. Anything this plan generates that launches Firefox — the per-profile `.desktop` files above all — must name the wrapper by absolute path. `run_onchange_after_configure_firefox_egl_workaround` already owns the `firefox.desktop`/`firefox-esr.desktop` overrides in `~/.local/share/applications/`; this plan's `firefox-profile-*.desktop` namespace sits beside them and must never collide with them.
- **Session env is uwsm, not Hyprland.** `MOZ_LEGACY_PROFILES=1` goes in `private_dot_config/uwsm/env.tmpl` (Task 2). Anything set via `hl.env()` never reaches `quickshell.service` or the apps its launcher spawns.
- **Classic `profiles.ini` only:** no `[Install…]` section, no `StoreID`. Profile identity is `IsRelative=1` + `Path=<id>`.
- **New SQLite selector disabled:** every profile's `user.js` sets `browser.profiles.enabled=false`. This is the in-app avatar switcher, and is unrelated to the classic Profile Manager, which stays enabled. Switching is via the picker, `about:profiles`, `firefox -P <id>`, or the generated `.desktop` launchers.
- **Migration strictly precedes profile management.** The `run_onchange` script refuses to run while `~/.mozilla/firefox` exists, because creating the XDG target dirs first would make the migration refuse to move real data. Task 3 before Task 4, enforced in code.
- **Task 5 (theming) depends on Tasks 3 and 4 and must NOT be parallelized with them.** Numeric order already puts it last, but the dependency is otherwise implicit and an agent fanning tasks out concurrently could run it early. If it runs before migration it selects the (existing, profile-less) XDG root, matches nothing, and exits 0 silently — indistinguishable from success. Tasks 1 and 2 may run in parallel; 3 → 4 → 5 is strictly sequential.
- **Addons stay global:** the existing enterprise policy (`.chezmoidata/firefox_policies.json` → `/usr/lib/firefox/distribution/policies.json`) applies to all profiles (the union). Per-profile addon scoping is explicitly out of scope here (deferred "specifics" work).
- **Script standards:** `.chezmoiscripts/` output uses log templates (`log_start`, `log_step`, `log_success`, `log_skip`, `log_warning`, `log_complete`) — never bare `echo`. Bash scripts use `set -euo pipefail`. Use `[ ]` not `[[ ]]`: the repo's `.shellcheckrc` enables `require-double-brackets` but pins `severity=warning`, so SC2292 is filtered and every existing script uses `[ ]`.
- **`chezmoi apply` takes TARGET paths, never source paths.** `chezmoi apply [target]...` — e.g. `chezmoi apply ~/.local/lib/scripts/desktop/theme-apply-firefox`. Entries under `.chezmoiscripts/` have **no target path at all** and cannot be applied selectively; test them by rendering to a file and running it.
- **Validation chain (this repo has no xUnit):** `chezmoi execute-template < file.tmpl` (renders Go template), pipe rendered shell to `shellcheck --severity=warning`, inspect generated output, `bash -n` / `sh -n` for syntax. A `.sh.tmpl` that passes `bash -n` on source can still render invalid shell — always validate **rendered** output.
- **Never write into a profile dir while Firefox is running** — the profile-management script warns; the migration script hard-refuses.
- **Commit after each task.**

---

## File Structure

| File | Responsibility | Action |
|------|----------------|--------|
| `.chezmoidata/firefox.yaml` | Single source of truth: profile list, default, common + per-profile prefs | Create |
| `private_dot_config/uwsm/env.tmpl` | Session env var `MOZ_LEGACY_PROFILES=1` (reaches compositor **and** systemd user manager) | Modify |
| `private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate` | One-time: reflink-backup, carry existing `Work`/`Perso` data into `work`/`leisure`, delete the stale stub, remove `~/.mozilla/firefox`, strip selector prefs | Create |
| `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl` | Materialize profile dirs, `user.js`, `profiles.ini`, `.desktop` launchers from the data file | Create |
| `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox` | Symlink theme `userChrome.css` into **every** managed profile; XDG-first | Modify |
| `.claude/rules/chezmoi-data.md` | Document the new `firefox.yaml` data file | Modify |

**Phasing and ordering:** Task 1 (data) and Task 2 (env var) are inert prerequisites and may run in parallel. **Tasks 3 → 4 → 5 are strictly sequential and must not be parallelized.** Task 3 (migration) must complete before Task 4 (profile management) — Task 4 enforces this itself via a runtime interlock. Task 5 (theming) must follow both; its dependency has no runtime interlock and fails *silently* if violated (see Global Constraints). Task 6 is a human verification gate, Task 7 documentation. The hybrid alternative is described in an appendix, not implemented.

**Rollback:** at any point after Task 3, the pre-migration state is restored wholesale by removing the XDG tree and moving the reflink backup back:

```bash
rm -rf ~/.config/mozilla/firefox
mv ~/.mozilla/firefox.backup-<ts> ~/.mozilla/firefox
```

Firefox reverts to the legacy tree the instant `~/.mozilla/firefox` exists again. The backup is a btrfs reflink copy taken before anything is touched, so it includes the stale `1cevmaad.default` stub that Task 3 deletes.

---

### Task 1: Firefox profile data file

**Files:**
- Create: `.chezmoidata/firefox.yaml`

**Interfaces:**
- Produces: template data `.firefox` with fields:
  - `.firefox.profile_root` (string, `$HOME`-relative) → `.config/mozilla/firefox`
  - `.firefox.default` (string) → profile `id` marked `Default=1`, i.e. the Profile Manager's preselected entry
  - `.firefox.common_prefs` (list of `{key, value}`) applied to every profile
  - `.firefox.profiles` (list of `{id, name, prefs}`) where `prefs` is a possibly-empty list of `{key, value}`
  - Pref `value` types: `string` values are quoted in `user.js`; `bool`/number values are emitted raw.

- [ ] **Step 1: Write the data file**

```yaml
# Firefox multi-profile configuration — single source of truth.
# Consumed by: .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
#              private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox (path only)
#
# Profile identity is managed via a classic profiles.ini (IsRelative=1 + Path=<id>).
# Requires MOZ_LEGACY_PROFILES=1 in the session environment, otherwise Firefox
# auto-creates and auto-binds a per-install dedicated profile, which suppresses
# both Default= and the Profile Manager.
# Firefox's new SQLite avatar selector is disabled (browser.profiles.enabled=false)
# so all state stays declarative; the classic Profile Manager stays enabled.
# Addons remain global via firefox_policies.json.

firefox:
  # XDG profile root, relative to $HOME. Firefox uses ~/.config/mozilla/firefox
  # when ~/.mozilla/firefox is absent.
  profile_root: ".config/mozilla/firefox"

  # Marked Default=1 in profiles.ini. With StartWithLastProfile=0 a plain `firefox`
  # always shows the Profile Manager; this is the entry it preselects, NOT a profile
  # that launches automatically. (Preselection behaviour is confirmed in Task 6 Step 3;
  # if Firefox ignores Default= under StartWithLastProfile=0, this field becomes inert
  # and can be dropped.)
  default: work

  # Applied to EVERY profile's user.js. String values are quoted; bool/number raw.
  common_prefs:
    - { key: "browser.profiles.enabled", value: false }                        # disable new SQLite selector
    - { key: "toolkit.legacyUserProfileCustomizations.stylesheets", value: true } # allow theme userChrome.css
    - { key: "browser.shell.checkDefaultBrowser", value: false }
    - { key: "browser.aboutConfig.showWarning", value: false }

  # Per-profile definitions. `prefs` overrides/extends common_prefs (same {key,value} shape).
  # Per-profile prefs are intentionally empty for now — the "specifics" pass fills these later.
  profiles:
    - id: work
      name: Work
      prefs: []
    - id: leisure
      name: Perso
      prefs: []
    - id: ringstone
      name: Ringstone
      prefs: []
```

- [ ] **Step 2: Verify chezmoi parses the data**

Run: `chezmoi data | jaq '.firefox'`
Expected: JSON object with `profile_root`, `default: "work"`, `common_prefs` (4 entries), and `profiles` (3 entries: work/Work, leisure/Perso, ringstone/Ringstone).

- [ ] **Step 3: Commit**

```bash
git add .chezmoidata/firefox.yaml
git commit -m "Add firefox.yaml: declarative multi-profile data source"
```

---

### Task 2: Session environment variable `MOZ_LEGACY_PROFILES=1`

Without this variable the entire declarative approach silently fails. Firefox applies per-install dedicated profiles: it creates a `*.default-release` profile of its own and binds it with an `[Install<HASH>]` section. Because that constitutes an automatic selection, it suppresses the classic Profile Manager as well as the authored `Default=1` — so under this plan's picker-based model the variable is not an optimization, it is the mechanism. This must land **before** any `profiles.ini` is authored.

**Where it goes — `uwsm/env.tmpl`, not Hyprland.** Session environment moved to `private_dot_config/uwsm/env.tmpl` on 2026-10-06. uwsm exports it to both the compositor *and* the systemd user manager; `hl.env()`/`env =` reached only Hyprland's own children. That matters here: the Quickshell launcher spawns apps via `systemd-run --user --scope`, so a variable set only in Hyprland never reaches a Firefox opened from the launcher. `hypr/conf/environment.lua` is now a deliberately empty stub that forbids new `hl.env()` calls (a second copy drifts) — do not touch it.

**Files:**
- Modify: `private_dot_config/uwsm/env.tmpl`

**Interfaces:**
- Produces: `MOZ_LEGACY_PROFILES=1` in the compositor and systemd user environment, inherited by every app launched from the session (Quickshell launcher, `.desktop` launchers, terminals).

- [ ] **Step 1: Add the variable to `uwsm/env.tmpl`**

In the `# Browser & Electron` section, find:

```sh
# Firefox native Wayland
export MOZ_ENABLE_WAYLAND=1
```

Add immediately after it:

```sh
# Make the managed profiles.ini authoritative: honour Default=1 and show the classic
# Profile Manager instead of Firefox's per-install dedicated profiles, which create their
# own *.default-release + [Install<HASH>] binding and suppress both.
export MOZ_LEGACY_PROFILES=1
```

- [ ] **Step 2: Render and apply**

Run:
```bash
chezmoi execute-template < private_dot_config/uwsm/env.tmpl | grep MOZ_LEGACY_PROFILES
chezmoi diff ~/.config/uwsm/env
```
Expected: `export MOZ_LEGACY_PROFILES=1`, and a diff containing only the added lines. Then `chezmoi apply ~/.config/uwsm/env` (user step).

- [ ] **Step 3: Load it into the session**

uwsm reads `env` once, at session start — there is no reload. **Log out and back in.** (`hyprctl reload` does not re-read it.)

Verify in both places the variable has to reach:
```bash
systemctl --user show-environment | grep MOZ_LEGACY_PROFILES   # systemd user manager -> Quickshell launches
hyprctl dispatch exec 'sh -c "echo $MOZ_LEGACY_PROFILES > /tmp/mlp.txt"'; sleep 1; cat /tmp/mlp.txt
```
Expected: `MOZ_LEGACY_PROFILES=1` and `1`. If either is empty, stop — do not proceed to Task 3.

- [ ] **Step 4: Pre-verify the picker against a throwaway `$HOME` (no real data at risk)**

**This step is a hard gate for Task 3, and it must run against the installed Firefox (157.0.1 on 2026-10-10).** Appendix A was recorded on 153 — four majors ago — so even its `StartWithLastProfile=1` rows are unproven here. Appendix A was also recorded under `StartWithLastProfile=1` and does **not** cover the `StartWithLastProfile=0` configuration this plan now ships. Rather than discover the answer mid-migration with 905 MB of real profile data in flight, prove it against a disposable tree first. Firefox derives its profile root from `$HOME`, so overriding `$HOME` fully isolates this.

```bash
TESTHOME="$(mktemp -d)"
mkdir -p "$TESTHOME/.config/mozilla/firefox/alpha" "$TESTHOME/.config/mozilla/firefox/beta"
cat > "$TESTHOME/.config/mozilla/firefox/profiles.ini" <<'EOF'
[General]
StartWithLastProfile=0
Version=2

[Profile0]
Name=Alpha
IsRelative=1
Path=alpha
Default=1

[Profile1]
Name=Beta
IsRelative=1
Path=beta
EOF
env HOME="$TESTHOME" MOZ_LEGACY_PROFILES=1 firefox -no-remote
```

`-no-remote` is required — without it Firefox hands the launch to the already-running instance and the test silently exercises your real profile instead.

Expected: the classic Profile Manager dialog appears listing exactly `Alpha` and `Beta`, with **`Alpha` preselected**. Close the dialog without launching, then confirm Firefox created nothing of its own:

```bash
ls -1 "$TESTHOME/.config/mozilla/firefox/"                 # alpha beta profiles.ini — no *.default-release
grep -c '^\[Install' "$TESTHOME/.config/mozilla/firefox/profiles.ini"   # expect 0
test ! -e "$TESTHOME/.config/mozilla/firefox/installs.ini" && echo "no installs.ini — OK"
rm -rf "$TESTHOME"
```

**Record the outcome, because two later steps branch on it:**
- Picker appears, `Alpha` preselected → plan is correct as written; proceed.
- Picker appears but preselection is arbitrary → `Default=1` is inert under `StartWithLastProfile=0`. Drop `default:` from `firefox.yaml` (Task 1), drop the `Default=1` emission from Task 4, and drop the preselection assertion from Task 6 Step 3.
- No picker, or a stray `*.default-release`/`[Install…]`/`installs.ini` appears → `MOZ_LEGACY_PROFILES=1` is not reaching Firefox. Stop; revisit Step 3 before touching real data.

- [ ] **Step 5: Commit**

```bash
git add private_dot_config/uwsm/env.tmpl
git commit -m "Set MOZ_LEGACY_PROFILES=1 so the managed Firefox profiles.ini is authoritative"
```

---

### Task 3: One-time migration of existing Work/Perso data (this machine)

Carries the existing `Work` (`nb2l5vl7.default-release`, 585 MB) and `Perso` (`tPJagWwW.Profile 1`, 320 MB) data — history, cookies, sessions — into `~/.config/mozilla/firefox/work` and `.../leisure`, deletes a stale third profile, removes `~/.mozilla/firefox` so Firefox switches to XDG, and strips the new-selector prefs for a clean classic break.

**This must run before Task 4.** Task 4 creates the XDG target directories; once they exist this script refuses to overwrite them, and the real browsing data would be stranded in the legacy tree.

The script is fail-safe by construction: it takes a complete backup before touching anything, only tears down the legacy tree if at least one profile actually moved, and aborts rather than skipping when a target already exists.

**Files:**
- Create: `private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate`

**Interfaces:**
- Consumes: `~/.mozilla/firefox/Profile Groups/<id>.sqlite` (name→dir map), existing profile dirs.
- Produces: `~/.config/mozilla/firefox/work`, `.../leisure`; a reflink backup at `~/.mozilla/firefox.backup-<ts>`; no remaining `~/.mozilla/firefox`.

> **Verified precondition (re-confirmed on Firefox 157.0.1, 2026-10-10):** `sqlite3 -readonly "$HOME/.mozilla/firefox/Profile Groups/3bfda0e8.sqlite" "SELECT name,path FROM Profiles;"` returns exactly `Work|nb2l5vl7.default-release` and `Perso|tPJagWwW.Profile 1`. The read succeeds despite a 1.5 MB uncheckpointed `-wal` alongside it.

> **⚠ The SQLite read is still the authority for names — keep it fatal.** As of 2026-10-10 the legacy `profiles.ini` *does* list Work (`[Profile0]`, `Name=default-release`, `Path=nb2l5vl7.default-release`, `StoreID=3bfda0e8`) — Firefox wrote it at some point after this plan was drafted, when the plan recorded it as INI-absent. But the INI names it `default-release`, not `Work`; the display names `Work`/`Perso` exist only in the group database, and `Perso` (`tPJagWwW.Profile 1`) is not in the INI at all. So the INI cannot identify which directory is "Work" or "Perso", and the script must `die` on any sqlite failure rather than guess — a wrong guess silently migrates the wrong 585 MB. (The `[Install4F96D1932A9F858E]` binding and `installs.ini` in the legacy tree go away with it.)

**Backup strategy:** `cp --reflink=always -a`. `$HOME` is btrfs (`/dev/mapper/root[/@home]`), so a copy-on-write clone of 905 MB is instantaneous and consumes essentially no additional space until the trees diverge. `always` rather than `auto` is deliberate — on a filesystem without reflink support the command fails loudly instead of silently degrading into a multi-minute full copy. This replaces the `tar --zstd` archive of earlier drafts: same safety, no CPU cost, no ~500 MB artifact left behind, and restoration is a `mv` rather than an extraction.

**Legacy teardown:** `rm -rf ~/.mozilla/firefox` outright, rather than renaming it to `firefox.migrated-<ts>`. The reflink backup is already a complete snapshot taken before any modification, so a second retained copy adds no recoverability — only two similarly-named stale trees in `~/.mozilla` to confuse a future reader. `~/.mozilla/extensions` is a sibling and is preserved; removing the `firefox` subdirectory alone is what flips Firefox to XDG.

**The stale third profile:** `1cevmaad.default` (4 KB, one file, untouched since Nov 2025, and currently the holder of `Default=1` in the legacy INI) is deleted explicitly. It is absent from the group database, so the name-driven migration would ignore it and it would vanish with the legacy tree anyway — the explicit `rm` makes it a decision rather than an accident. It remains recoverable from the reflink backup, which is taken first.

- [ ] **Step 1: Write the migration script**

```bash
#!/usr/bin/env bash

# Script: firefox-profiles-migrate
# Purpose: One-time migration of existing Firefox profiles into the XDG classic-declarative
#          layout (Work -> work, Perso -> leisure). Removes ~/.mozilla/firefox so Firefox
#          adopts the XDG base dir.
# Requirements: Firefox closed, sqlite3 (for name mapping), btrfs $HOME (reflink), bash

set -euo pipefail

LEGACY_FF="$HOME/.mozilla/firefox"
XDG_FF="$HOME/.config/mozilla/firefox"
TS="$(date +%Y%m%d%H%M%S)"
BACKUP="$HOME/.mozilla/firefox.backup-$TS"

# Stale profile dirs to delete outright rather than carry forward. Verified empty-ish:
# 1cevmaad.default is 4 KB / 1 file, untouched since Nov 2025, absent from the group DB.
# Recoverable from $BACKUP if this turns out to be wrong.
STALE_DIRS=("1cevmaad.default")

log()  { printf '→ %s\n' "$1"; }
warn() { printf '⚠️  %s\n' "$1" >&2; }
die()  { printf '❌ %s\n' "$1" >&2; exit 1; }

# 1. Firefox must be closed — moving a live profile corrupts it.
if pgrep -x firefox >/dev/null 2>&1; then
    die "Firefox is running. Close it completely, then re-run."
fi

# 2. Anything to migrate?
[ -d "$LEGACY_FF" ] || { log "No ~/.mozilla/firefox found — nothing to migrate."; exit 0; }

# 3. Full backup before touching anything. --reflink=always so this fails loudly on a
#    non-btrfs filesystem rather than silently turning into a multi-minute 905 MB copy.
[ -e "$BACKUP" ] && die "Backup path '$BACKUP' already exists — refusing to overwrite."
log "Reflink-backing up ~/.mozilla/firefox -> $BACKUP"
cp --reflink=always -a "$LEGACY_FF" "$BACKUP" \
    || die "Reflink backup failed (is \$HOME on btrfs?). Nothing moved."

# 4. Map display names -> profile dirs via the SelectableProfileService sqlite.
#    This is the ONLY way to identify 'Work': nb2l5vl7.default-release is absent from
#    profiles.ini entirely. No fallback exists, so every failure below is fatal.
declare -A NAME_TO_DIR=()
GROUP_DB="$(find "$LEGACY_FF/Profile Groups" -maxdepth 1 -name '*.sqlite' 2>/dev/null | head -1 || true)"
if [ -z "$GROUP_DB" ]; then
    die "No 'Profile Groups/*.sqlite' found — cannot map profile names. Nothing moved; $BACKUP kept."
fi
command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 not installed — cannot map profile names. Nothing moved."

while IFS='|' read -r pname ppath; do
    if [ -n "$pname" ]; then
        NAME_TO_DIR["$pname"]="$ppath"
    fi
done < <(sqlite3 -readonly "$GROUP_DB" "SELECT name,path FROM Profiles;")

[ "${#NAME_TO_DIR[@]}" -gt 0 ] || die "Profiles table empty or unreadable — nothing moved; $BACKUP kept."
log "Discovered ${#NAME_TO_DIR[@]} profile name(s): ${!NAME_TO_DIR[*]}"

mkdir -p "$XDG_FF"

MOVED=0
move_profile() {  # $1 = legacy display name, $2 = new id
    local legacy_name="$1" new_id="$2" src dst
    src="$LEGACY_FF/${NAME_TO_DIR[$legacy_name]:-}"
    dst="$XDG_FF/$new_id"

    [ -n "${NAME_TO_DIR[$legacy_name]:-}" ] || { warn "No profile named '$legacy_name' in the group DB — skipping '$new_id'."; return 0; }
    [ -d "$src" ] || { warn "Source dir '$src' not found — skipping '$new_id'."; return 0; }

    # A non-empty target means the managed run_onchange script already ran. Refuse:
    # silently skipping here is how real browsing data gets stranded.
    if [ -e "$dst" ] && [ -n "$(ls -A "$dst" 2>/dev/null)" ]; then
        die "Target '$dst' already exists and is not empty. The profile-management script ran before this migration. Resolve manually; nothing else moved."
    fi
    rmdir "$dst" 2>/dev/null || true

    mv "$src" "$dst"
    # Strip new-selector linkage for a clean classic break (Firefox is closed).
    if [ -f "$dst/prefs.js" ]; then
        sed -i '/browser\.profiles\./d; /toolkit\.profiles\.storeID/d' "$dst/prefs.js"
    fi
    MOVED=$((MOVED + 1))
    log "Migrated '$legacy_name' -> $new_id"
}

# 5. Perform the known mappings.
move_profile Work  work
move_profile Perso leisure

# 6. Only tear down the legacy tree if something actually moved.
[ "$MOVED" -gt 0 ] || die "No profiles were migrated — leaving ~/.mozilla/firefox untouched. Backup: $BACKUP"

# 7. Delete stale profile dirs explicitly, so their removal is a decision on the
#    record rather than a side effect of the teardown below. Still in $BACKUP.
for stale in "${STALE_DIRS[@]}"; do
    if [ -d "$LEGACY_FF/$stale" ]; then
        rm -rf "${LEGACY_FF:?}/$stale"
        log "Deleted stale profile '$stale' (recoverable from $BACKUP)."
    fi
done

# 8. Remove the legacy tree. Firefox selects the legacy base on the existence of
#    ~/.mozilla/firefox, not ~/.mozilla — so this preserves ~/.mozilla/extensions
#    and any other sibling data. $BACKUP is a complete pre-migration snapshot, which
#    is why nothing is retained here under a .migrated-* name.
rm -rf "${LEGACY_FF:?}"
log "Removed ~/.mozilla/firefox (Firefox will now use ~/.config/mozilla)."

printf '\n✅ Migrated %s profile(s). Backup: %s\n\nNext:\n  chezmoi apply\n(to write user.js/profiles.ini, create the ringstone profile, and launchers)\n\nRollback:\n  rm -rf %s && mv %s %s\n' \
    "$MOVED" "$BACKUP" "$XDG_FF" "$BACKUP" "$LEGACY_FF"
```

- [ ] **Step 2: Syntax + lint**

Run:
```bash
bash -n private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
shellcheck --severity=warning private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
```
Expected: no syntax errors; shellcheck exits 0. (Associative arrays and process substitution require the `#!/usr/bin/env bash` shebang, which is present.)

- [ ] **Step 3: Apply the script into place**

Run:
```bash
chezmoi apply ~/.local/lib/scripts/utils/firefox-profiles-migrate
ls -l ~/.local/lib/scripts/utils/firefox-profiles-migrate
```
Expected: file exists, mode `-rwxr-xr-x`.

- [ ] **Step 4: Execute the migration (destructive — backup is automatic)**

> Close Firefox completely first. This moves live browsing data. The script refuses to run otherwise.

Run: `~/.local/lib/scripts/utils/firefox-profiles-migrate`

Expected output:
```
→ Reflink-backing up ~/.mozilla/firefox -> /home/amaury/.mozilla/firefox.backup-<ts>
→ Discovered 2 profile name(s): Work Perso
→ Migrated 'Work' -> work
→ Migrated 'Perso' -> leisure
→ Deleted stale profile '1cevmaad.default' (recoverable from ...).
→ Removed ~/.mozilla/firefox (Firefox will now use ~/.config/mozilla).

✅ Migrated 2 profile(s). Backup: /home/amaury/.mozilla/firefox.backup-<ts>
...
```

Then verify:
```bash
ls -1 ~/.config/mozilla/firefox/          # work/ leisure/ present, with real data
du -sh ~/.config/mozilla/firefox/work ~/.config/mozilla/firefox/leisure  # ~585M / ~320M
ls -1 ~/.mozilla/                         # extensions/ preserved, firefox.backup-<ts>/
test ! -e "$HOME/.mozilla/firefox" && echo "legacy removed OK"
grep -c 'browser.profiles' ~/.config/mozilla/firefox/work/prefs.js   # expect 0
```

Confirm the backup is a real reflink clone and cost nothing:
```bash
du -sh --apparent-size ~/.mozilla/firefox.backup-*   # ~905M apparent
btrfs filesystem du -s ~/.mozilla/firefox.backup-*   # 'exclusive' should be ~0
```
A large `exclusive` figure means the copy was not reflinked — the data is safe either way, but investigate before relying on the "free rollback" assumption.

If the script aborts with a `❌` message, **nothing was moved and the legacy tree is intact** — read the message, fix the cause, re-run.

- [ ] **Step 5: Commit**

```bash
git add private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
git commit -m "Add one-time Firefox Work/Perso -> XDG classic profile migration helper"
```

---

### Task 4: Profile-management run_onchange script

Creates profile directories, `user.js`, `profiles.ini`, and `.desktop` launchers from `firefox.yaml`. Idempotent and additive: it never deletes an existing profile directory, so it composes with the Task 3 migration.

The interlock at the top makes the Task 3 → Task 4 ordering self-enforcing rather than a prose instruction.

**Files:**
- Create: `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl`

**Interfaces:**
- Consumes: `.firefox.*` from Task 1; `MOZ_LEGACY_PROFILES=1` from Task 2; migrated dirs from Task 3.
- Produces (on disk): `~/.config/mozilla/firefox/<id>/user.js`, `~/.config/mozilla/firefox/profiles.ini`, `~/.local/share/applications/firefox-profile-<id>.desktop`.

- [ ] **Step 1: Write the script template**

```bash
#!/usr/bin/env bash

# Script: run_onchange_after_manage_firefox_profiles.sh
# Purpose: Declaratively manage Firefox profiles (XDG): dirs, user.js, profiles.ini, launchers
# Requirements: Arch Linux, firefox, MOZ_LEGACY_PROFILES=1 in the session environment

# Hash: {{ .firefox | toJson | sha256sum }}

{{ includeTemplate "log_start" "Managing Firefox profiles..." }}

set -euo pipefail

if ! command -v firefox >/dev/null 2>&1; then
    {{ includeTemplate "log_skip" "Firefox not installed, skipping" }}
    exit 0
fi

PROFILE_ROOT="$HOME/{{ .firefox.profile_root }}"
APP_DIR="$HOME/.local/share/applications"

# Interlock: while ~/.mozilla/firefox exists Firefox ignores the XDG base entirely,
# so anything written here is dead config — and creating the target dirs would make
# firefox-profiles-migrate refuse. Migration must happen first.
if [ -d "$HOME/.mozilla/firefox" ]; then
    {{ includeTemplate "log_warning" "Legacy ~/.mozilla/firefox present — run 'firefox-profiles-migrate' first, then re-apply. Skipping." }}
    exit 0
fi

if pgrep -x firefox >/dev/null 2>&1; then
    {{ includeTemplate "log_warning" "Firefox is running — restart it for profile changes to take effect" }}
fi

{{ includeTemplate "log_step" "Ensuring XDG profile root..." }}
mkdir -p "$PROFILE_ROOT" "$APP_DIR"

# --- Per-profile directories + user.js -------------------------------------
{{ range .firefox.profiles }}
{{ includeTemplate "log_step" (printf "Configuring profile: %s" .name) }}
mkdir -p "$PROFILE_ROOT/{{ .id }}"
cat > "$PROFILE_ROOT/{{ .id }}/user.js" <<'USERJS_EOF'
// Managed by chezmoi — do not edit. Source: .chezmoidata/firefox.yaml
{{ range $.firefox.common_prefs -}}
user_pref("{{ .key }}", {{ if kindIs "string" .value }}"{{ .value }}"{{ else }}{{ .value }}{{ end }});
{{ end -}}
{{ range .prefs -}}
user_pref("{{ .key }}", {{ if kindIs "string" .value }}"{{ .value }}"{{ else }}{{ .value }}{{ end }});
{{ end -}}
USERJS_EOF
{{ end }}
# --- Classic profiles.ini (no Install/StoreID) -----------------------------
# StartWithLastProfile=0 => plain `firefox` always shows the classic Profile Manager
# instead of silently reopening whatever was used last. Default=1 marks the entry the
# manager preselects. Both only work under MOZ_LEGACY_PROFILES=1: without it Firefox
# applies per-install dedicated profiles, which auto-select a profile of its own making
# and so suppress the picker entirely.
if [ -f "$PROFILE_ROOT/profiles.ini" ] && grep -q '^\[Install' "$PROFILE_ROOT/profiles.ini"; then
    {{ includeTemplate "log_warning" "profiles.ini has an [Install] section — Firefox ran without MOZ_LEGACY_PROFILES=1. Check the session environment; a stray *.default-release profile may exist." }}
fi

{{ includeTemplate "log_step" "Writing profiles.ini..." }}
cat > "$PROFILE_ROOT/profiles.ini" <<'PROFILES_EOF'
[General]
StartWithLastProfile=0
Version=2
{{ range $i, $p := .firefox.profiles }}
[Profile{{ $i }}]
Name={{ $p.name }}
IsRelative=1
Path={{ $p.id }}
{{ if eq $p.id $.firefox.default }}Default=1
{{ end }}{{- end }}
PROFILES_EOF

# --- Per-profile .desktop launchers (pruned + regenerated) -----------------
# Exec carries MOZ_LEGACY_PROFILES inline so a launcher works even if the session
# environment is missing it (e.g. launched from a non-uwsm context). `firefox -P <id>`
# bypasses the Profile Manager, so launchers go straight to their profile.
#
# Exec names the EGL wrapper by ABSOLUTE path, never bare `firefox`. The real binary
# (/usr/lib/firefox/firefox) never maps a window on this NVIDIA machine without the
# wrapper's egl-wayland2 workaround (see _research/FIREFOX_NVIDIA_EGL_DEADLOCK.md), and
# `.desktop` launches bypass PATH ordering: a Quickshell/systemd-run or xdg-open launch
# does not necessarily put ~/.local/bin ahead of /usr/bin. The same reason
# run_onchange_after_configure_firefox_egl_workaround rewrites the system firefox.desktop.
#
# The prune glob is deliberately namespaced to 'firefox-profile-*': a bare 'firefox-*'
# would also match hand-written entries like firefox-esr.desktop or firefox-dev.desktop
# that this script does not own. (Today the only other entry is the
# ~/.local/share/applications/firefox.desktop override that configure_firefox_egl_workaround
# generates; the glob leaves it alone, and it — wrapper-routed — remains the picker entry point.)
{{ includeTemplate "log_step" "Generating per-profile launchers..." }}
rm -f "$APP_DIR"/firefox-profile-*.desktop
{{ range .firefox.profiles }}
cat > "$APP_DIR/firefox-profile-{{ .id }}.desktop" <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox — {{ .name }}
Comment=Browse the Web ({{ .name }} profile)
Exec=env MOZ_LEGACY_PROFILES=1 {{ $.chezmoi.homeDir }}/.local/bin/firefox -P {{ .id }} %U
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=firefox
DESKTOP_EOF
{{ end }}
{{ includeTemplate "log_complete" "Firefox profiles managed" }}
```

- [ ] **Step 2: Render the template and confirm it produces valid shell**

Run:
```bash
chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl \
  > /tmp/ff-profiles.rendered.sh
```
Expected: exit 0. Confirm in the output that the `user.js` heredoc for `work` contains `user_pref("browser.profiles.enabled", false);` (unquoted `false`) and `user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);`, and that the `profiles.ini` heredoc reads `StartWithLastProfile=0` with three `[ProfileN]` blocks, `Default=1` appearing only under `Path=work`.

- [ ] **Step 3: Lint the rendered shell**

Run: `shellcheck --severity=warning /tmp/ff-profiles.rendered.sh && bash -n /tmp/ff-profiles.rendered.sh`
Expected: both exit 0, no output.

- [ ] **Step 4: Run it**

`.chezmoiscripts/` entries have no target path, so `chezmoi apply <path>` cannot address them. Either run the rendered copy directly, or run a full `chezmoi apply` (which executes it because the hash is new):

```bash
bash /tmp/ff-profiles.rendered.sh
```
Expected: log lines through `🎉 Firefox profiles managed`. If it prints the legacy-interlock warning instead, Task 3 has not completed — go back and finish it.

- [ ] **Step 5: Verify on disk**

Run:
```bash
ls -1 ~/.config/mozilla/firefox/
cat ~/.config/mozilla/firefox/profiles.ini
grep browser.profiles.enabled ~/.config/mozilla/firefox/work/user.js
ls -1 ~/.local/share/applications/firefox-profile-*.desktop
```
Expected: three profile dirs each with `user.js`; `profiles.ini` valid, `StartWithLastProfile=0`, `Default=1` under `Path=work`; `user_pref("browser.profiles.enabled", false);` present; three launcher files named `firefox-profile-{work,leisure,ringstone}.desktop`, each with an `Exec=` naming `$HOME/.local/bin/firefox` (the EGL wrapper), not bare `firefox`.

- [ ] **Step 6: Commit**

```bash
git add .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
git commit -m "Add run_onchange script to manage Firefox profiles declaratively"
```

---

### Task 5: Retarget theme-apply-firefox to XDG + all profiles

The current script is dead, and has been since November 2025. Its XDG-first branch already matches (`~/.config/mozilla/firefox/` exists, holding only `Crash Reports/`), it then probes for `*.default-release` underneath, finds nothing, and exits 0. The live legacy profile has never been reached from that branch. Rewrite it to prefer the XDG root and symlink `userChrome.css` into **every** managed profile.

> **⚠ Sequencing (no runtime interlock — violation is silent).** This task depends on Tasks 3 and 4 and must not be run concurrently with them. Run it before migration and it selects the same profile-less XDG root, matches nothing, and exits 0 — identical to a clean success. The silent `exit 0` is kept deliberately: `private_dot_local/lib/scripts/CLAUDE.md:114` documents that every `theme-apply-*` script skips silently when its app is absent, and diverging here would be inconsistent with the theme system's contract. Correct ordering is what protects this, not the script.

**Files:**
- Modify: `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox`

**Interfaces:**
- Consumes: `~/.config/themes/current/firefox-userChrome.css` (existing theme asset), profile dirs from Task 4.
- Produces: `~/.config/mozilla/firefox/<id>/chrome/userChrome.css` symlink per profile.
- Called by: `private_dot_local/lib/scripts/desktop/executable_theme-switcher.tmpl:141` as `~/.local/lib/scripts/desktop/theme-apply-firefox`.

- [ ] **Step 1: Replace the file contents**

```sh
#!/usr/bin/env sh

# Script: theme-apply-firefox.sh
# Purpose: Apply current dotfiles theme to every Firefox profile via userChrome.css
# Requirements: Arch Linux, Firefox
# Note: profiles set toolkit.legacyUserProfileCustomizations.stylesheets=true via managed user.js

THEME_DIR="$HOME/.config/themes/current"
[ -L "$THEME_DIR" ] || exit 0

USERCHROME_SOURCE="$THEME_DIR/firefox-userChrome.css"
[ -f "$USERCHROME_SOURCE" ] || exit 0

# XDG-first, then legacy fallback
if [ -d "$HOME/.config/mozilla/firefox" ]; then
    FIREFOX_DIR="$HOME/.config/mozilla/firefox"
elif [ -d "$HOME/.mozilla/firefox" ]; then
    FIREFOX_DIR="$HOME/.mozilla/firefox"
else
    exit 0
fi

# Symlink userChrome.css into every profile directory. The user.js/prefs.js test
# distinguishes real profiles from siblings like "Crash Reports" / "Pending Pings".
found=0
for profile in "$FIREFOX_DIR"/*/; do
    [ -d "$profile" ] || continue
    if [ -f "${profile}user.js" ] || [ -f "${profile}prefs.js" ]; then
        chrome_dir="${profile}chrome"
        mkdir -p "$chrome_dir"
        rm -f "$chrome_dir/userChrome.css"
        ln -sf "$USERCHROME_SOURCE" "$chrome_dir/userChrome.css"
        found=1
    fi
done

[ "$found" -eq 1 ] || exit 0
```

- [ ] **Step 2: Syntax-check**

Run: `sh -n private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox`
Expected: no output (valid).

- [ ] **Step 3: Shellcheck (POSIX)**

Run: `shellcheck -s sh --severity=warning private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox`
Expected: exit 0, no output.

- [ ] **Step 4: Apply and verify symlinks exist for all profiles**

Run:
```bash
chezmoi apply ~/.local/lib/scripts/desktop/theme-apply-firefox
~/.local/lib/scripts/desktop/theme-apply-firefox
ls -l ~/.config/mozilla/firefox/*/chrome/userChrome.css
```
Expected: a `userChrome.css` symlink under each profile's `chrome/` pointing into `~/.config/themes/current/`. (If the current theme provides no `firefox-userChrome.css`, the script exits 0 silently and the `ls` finds nothing — acceptable.)

- [ ] **Step 5: Commit**

```bash
git add private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
git commit -m "Retarget theme-apply-firefox to XDG and all managed profiles"
```

---

### Task 6: End-to-end verification (human gate)

No new files. Steps 2–4 need an interactive GUI session and cannot be completed by an agent — this task is a checkpoint for a human operator.

**Files:** none (verification only).

- [ ] **Step 1: Automated render/lint sweep**

Run:
```bash
chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl \
  | shellcheck --severity=warning -
sh -n private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
shellcheck --severity=warning private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
chezmoi data | jaq '.firefox.profiles | length'   # expect 3
```
Expected: clean shellcheck on all three, clean `sh -n`, `3`.

- [ ] **Step 2: Confirm Firefox adopts the profiles (Firefox closed)**

Run: `firefox -P` (classic Profile Manager dialog).
Expected: `Work`, `Perso`, `Ringstone` listed, and no others.

- [ ] **Step 3: Confirm plain `firefox` shows the picker and creates nothing**

Run: `firefox` (no arguments).

Expected: the classic Profile Manager appears listing `Work`, `Perso`, `Ringstone`, **with `Work` preselected**. This is the real-data confirmation of what Task 2 Step 4 established against a throwaway `$HOME`; if preselection did not work there, expect an arbitrary highlight here and apply the fallback recorded in that step (drop `default:` from `firefox.yaml`, drop `Default=1` from Task 4, drop this assertion).

Choose `Work`, then visit `about:profiles`. Expected: the current profile is rooted at `~/.config/mozilla/firefox/work`, carrying your existing history and sessions.

Then, with Firefox closed again:

```bash
ls -1 ~/.config/mozilla/firefox/        # exactly: work leisure ringstone (+ Crash Reports, Pending Pings, profiles.ini)
grep -c '^\[Install' ~/.config/mozilla/firefox/profiles.ini   # expect 0
grep StartWithLastProfile ~/.config/mozilla/firefox/profiles.ini   # expect StartWithLastProfile=0
test ! -e ~/.config/mozilla/firefox/installs.ini && echo "no installs.ini — MOZ_LEGACY_PROFILES is working"
```
Expected: no stray `*.default-release` directory, no `[Install…]` section, no `installs.ini`, and `StartWithLastProfile` still `0` (Firefox rewrites `profiles.ini` on exit — a flip back to `1` means something re-enabled last-profile behaviour). Any of those appearing means `MOZ_LEGACY_PROFILES=1` did not reach Firefox — revisit Task 2 Step 3.

- [ ] **Step 4: Confirm the picker is not sticky**

Launch `firefox`, choose `Perso`, browse briefly, quit. Launch plain `firefox` again.
Expected: the Profile Manager appears **again** — it does not skip straight to `Perso`. This is the specific regression `StartWithLastProfile=0` exists to prevent, and the one that silently reappears if Firefox rewrites the flag.

- [ ] **Step 5: Confirm the avatar selector is gone and launchers bypass the picker**

Launch `firefox -P work`. Expected: **no** profile avatar button in the toolbar (that is the new SQLite selector, disabled via `user.js`); `about:config` shows `browser.profiles.enabled` = `false` (user-set). Note the classic Profile Manager is unaffected by this pref — the two mechanisms are independent.

Run: `gtk-launch firefox-profile-leisure` (or pick "Firefox — Perso" in Wofi).
Expected: Firefox opens the `leisure` profile directly, **with no picker** (confirm via `about:profiles`). The launcher will show four Firefox entries — the three managed launchers plus the `firefox.desktop` override (wrapper-routed by `configure_firefox_egl_workaround`), which is the intentional picker entry point. Confirm the window actually *maps* from a launcher entry — an unwrapped launch shows processes and no window.

- [ ] **Step 6: Record the verification**

```bash
git commit --allow-empty -m "Verify declarative Firefox profile core end-to-end"
```

> **Backup retention.** `~/.mozilla/firefox.backup-<ts>` is a reflink clone consuming almost no space, so there is no pressure to remove it. Keep it until you have used all three profiles across several sessions and are satisfied nothing is missing; then `rm -rf ~/.mozilla/firefox.backup-*`. Note that space is only reclaimed for blocks the migrated profiles have since rewritten — the shared extents stay alive as long as either copy references them.

---

### Task 7: Document the data file

**Files:**
- Modify: `.claude/rules/chezmoi-data.md`

- [ ] **Step 1: Add `firefox.yaml` to the Data Files Overview table**

In the "Data Files Overview" table, add a row after the `ai.yaml` row:

```markdown
| `firefox.yaml` | Firefox profiles (classic declarative): list, default, per-profile prefs | `{{ .firefox.* }}` |
```

- [ ] **Step 2: Add a hash-trigger table row**

In the "Hash-Triggered Scripts" table, add:

```markdown
| `firefox.yaml` | `run_onchange_after_manage_firefox_profiles.sh.tmpl` | AFTER file application |
```

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/chezmoi-data.md
git commit -m "Document firefox.yaml data file and its hash trigger"
```

---

## Appendix A: Verified Firefox behaviour (153.0.1)

Recorded because several of these contradict the obvious reading of the docs, and the plan's correctness depends on them.

> **⚠ Version gap.** Every row below was recorded on Firefox **153.0.1** (partly re-confirmed on 153.0.3). The installed Firefox on 2026-10-10 is **157.0.1**. Nothing here has been re-proved on 157 — `MOZ_LEGACY_PROFILES` is an escape hatch for Mozilla's dedicated-profiles rollout and is the claim most likely to have moved. Task 2 Step 4 re-proves the whole table's load-bearing rows before any real data moves.
>
> **⚠ Coverage gap.** Every row below was recorded under `StartWithLastProfile=1`. The plan now ships `StartWithLastProfile=0`, and **nothing here tests that configuration.** The rows remain individually true — they concern the XDG root, the legacy trigger, and the dedicated-profiles mechanism, none of which depend on this flag — but the picker behaviour and `Default=1`-as-preselection are *inferred*, not verified. Task 2 Step 4 closes the gap against a throwaway `$HOME` before any real data moves; Task 6 Step 3 confirms it on the real tree. Do not treat preselection as established until one of those has run.

> Local environment re-confirmed on Firefox **153.0.3** (plan drafted against 153.0.1; the sqlite name map was re-read on 157.0.1 on 2026-10-10 and is unchanged, nothing else here was): sqlite name map unchanged; `[Install4F96D1932A9F858E]` with `Locked=1` present in the legacy `profiles.ini`, overriding the `Default=1` carried by `1cevmaad.default` — a direct in-situ demonstration of the row below.

| Claim | Result |
|---|---|
| XDG profile root | Profile dirs **and** `profiles.ini` both under `$XDG_CONFIG_HOME/mozilla/firefox`. `XDG_DATA_HOME` is not used for profiles. |
| Legacy trigger | `~/.mozilla/firefox`, **not** `~/.mozilla`. An empty `~/.mozilla` still yields XDG. |
| `Default=1` alone | **Ignored.** Firefox created its own `vrte1071.default-release`, added `[Install4F96D1932A9F858E]` + `installs.ini`, left the managed profiles untouched. |
| `Default=1` + `MOZ_LEGACY_PROFILES=1` | **Honoured.** Managed profile used, no stray profile, `profiles.ini` left byte-identical. |
| `[Install<HASH>]` written by hand | Also works, but `HASH` is derived from the installation directory — machine/path specific, and unavailable on a fresh install. Rejected in favour of the env var. |
| Profile-group SQLite | `Profiles` table is 7 columns (`id, path, name, avatar, themeId, themeFg, themeBg`); `SELECT name,path` yields `Work|nb2l5vl7.default-release`, `Perso|tPJagWwW.Profile 1`. Readable via `-readonly` despite a 1.5 MB uncheckpointed `-wal`. |
| Selector-created profiles vs `profiles.ini` | Recorded on 153: `nb2l5vl7.default-release` (Work) was **absent from `profiles.ini`**. **Superseded 2026-10-10:** it now appears as `[Profile0]` named `default-release` with `StoreID=3bfda0e8`, while `Perso` (`tPJagWwW.Profile 1`) is still absent. Display names live only in the group DB, so the sqlite map remains the only reliable discovery path. |

## Appendix B: The "Hybrid" Alternative (not implemented)

This plan implements **classic declarative** — the robust path that gives up Firefox's new in-app avatar/theme profile switcher in exchange for zero coupling to a browser-owned, version-unstable SQLite schema. If the in-app avatar switcher turns out to be a must-have, the **hybrid (reconcile)** approach is the fallback. It is documented here so the decision — and its cost — stays visible.

**What it adds over this plan:**

- **Keep** `browser.profiles.enabled=true` (drop that line from `common_prefs`) and drop `MOZ_LEGACY_PROFILES=1` (Task 2).
- **Do not** write `profiles.ini` by hand. Instead, let Firefox bootstrap a profile *group* once (its `StoreID`, group UUIDs, schema migrations, and `Profile Groups/<StoreID>.sqlite` all created by Firefox — never authored by us).
- Add a **reconcile step** (Firefox closed, WAL checkpointed) that opens the existing `Profile Groups/<StoreID>.sqlite` and `INSERT`/`UPDATE`s **only** the 7-column `Profiles` table so its rows match `firefox.yaml` — pointing `path` at the same `work`/`leisure`/`ringstone` dirs this plan creates. `avatar`/`themeId`/`themeFg`/`themeBg` become new per-profile fields in `firefox.yaml`.

**Why it is the fallback, not the default:**

- The `SelectableProfileService` schema is new (~FF 140), undocumented, and evolving — a Firefox update can change it and silently break the reconcile step.
- Identity is spread across `profiles.ini` (`StoreID`), `installs.ini`, the SQLite filename, and per-profile prefs (`toolkit.profiles.storeID`, `browser.profiles.*`, group UUIDs in `SharedPrefs`). We would only safely own the `Profiles` table; the rest must remain Firefox-managed.
- It requires Firefox fully closed on every apply (WAL lock), versus this plan where only `profiles.ini` edits benefit from a closed browser and `user.js` is always safe.

**Migration under hybrid:** the Task 3 helper would **not** strip `browser.profiles.*`/`toolkit.profiles.storeID`, and would **not** retire `Profile Groups/` — it would keep Firefox's group intact and let the reconcile step rewrite the `Profiles` rows to the new dir names.

If this fallback is ever chosen, it is a separate spec/plan cycle: it changes Task 1 (add avatar/theme fields), removes Task 2, replaces Task 4's `profiles.ini` generation with a reconcile script, and alters Task 3's teardown.

**Residual risk of the chosen path:** `MOZ_LEGACY_PROFILES` is an escape hatch for Mozilla's dedicated-profiles rollout and could be removed in a future release. If it disappears, the symptom is exactly what Task 6 step 3 checks for — a stray `*.default-release` and an `[Install…]` section — and the fix is to fall back to emitting the `[Install<HASH>]` section from the hash already present in `profiles.ini`.

---

## Self-Review

**Spec coverage** (against the brainstorm decisions):
- Three profiles `work`/`leisure`/`ringstone` → Task 1 data, Task 4 materialization. ✅
- Context separation (distinct cookies/logins/history) → inherent to separate profile dirs; migration preserves existing data (Task 3). ✅
- Privacy secondary → `common_prefs` scaffolding + global enterprise policy retained (Global Constraints); per-profile privacy prefs are data-file additions, deferred by user request. ✅
- XDG target `~/.config/mozilla/firefox` → Global Constraints + Tasks 3/4/5. ✅
- Classic declarative (avatar selector disabled, `profiles.ini` authored) → Task 2 + Task 4 + `browser.profiles.enabled=false`. ✅
- Picker-on-every-plain-launch (`StartWithLastProfile=0`, `Default=1` as preselection) → Task 4, pre-verified in Task 2 Step 4, confirmed in Task 6 Steps 3–4. ✅
- Map existing Work→work, Perso→leisure → Task 3 (sqlite name map + `move_profile`). ✅
- In-Firefox / launcher switching → Task 4 `.desktop` launchers + `about:profiles`/`firefox -P` (Task 6 verify). ✅
- Fix the dead profile probe in the theme script → Task 5, with the real cause (pre-existing empty XDG root) recorded rather than the earlier misdiagnosis of probe order. ✅
- Reflink backup, stale-stub deletion, single-copy teardown, documented rollback → Task 3 + File Structure "Rollback". ✅
- Mention hybrid alternative → Appendix B. ✅

**Open question carried into execution:** whether `Default=1` preselects under `StartWithLastProfile=0`. It is unverified by Appendix A, cheap to test (Task 2 Step 4, throwaway `$HOME`), and inert if false — the fallback is deleting three lines. This is the plan's only deliberate unknown; everything else asserted here was verified empirically on 153.0.1 or re-confirmed on 153.0.3 — **not yet on the installed 157.0.1**, which Task 2 Step 4 now covers.

**Placeholder scan:** No `TBD`/`TODO`/"handle edge cases". Empty `prefs: []` is a concrete valid state (deferred specifics), not a placeholder — every step ships runnable content. ✅

**Type/name consistency:** `.firefox.profile_root`, `.firefox.default`, `.firefox.common_prefs[].{key,value}`, `.firefox.profiles[].{id,name,prefs}` used identically in Tasks 1 and 4; profile ids `work`/`leisure`/`ringstone` consistent across data, script, theme loop, launchers, and migration targets; `move_profile <displayName> <newId>` matches its two call sites (note: takes the *display name*, and resolves the directory through `NAME_TO_DIR` internally). ✅

**Ordering consistency:** Task 3 (migration) precedes Task 4 (management) in numbering, in the File Structure phasing note, in the Global Constraints, and is enforced at runtime by Task 4's interlock plus Task 3's non-empty-target refusal. ✅

**Command correctness:** every `chezmoi apply` in this plan names a target path under `$HOME`; the `.chezmoiscripts/` entry is exercised via `chezmoi execute-template` + `bash` because it has no target path. ✅
