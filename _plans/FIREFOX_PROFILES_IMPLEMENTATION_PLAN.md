# Firefox Multi-Profile (Classic Declarative) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage three Firefox profiles (`work`, `leisure`, `ringstone`) declaratively from a single chezmoi data file, targeting Firefox's XDG profile location, with per-profile `user.js`, a generated `profiles.ini`, per-profile theme `userChrome.css`, and per-profile `.desktop` launchers.

**Architecture:** A new `.chezmoidata/firefox.yaml` is the single source of truth. A hash-triggered `run_onchange` chezmoi-template script ranges over that data to create each profile directory under `~/.config/mozilla/firefox/`, write its `user.js`, generate a classic `profiles.ini`, and emit per-profile launchers. The existing `theme-apply-firefox` script is retargeted to XDG and loops over every managed profile. Firefox's new SQLite-backed profile selector (`SelectableProfileService`) is deliberately disabled (`browser.profiles.enabled=false`) so all profile identity lives in the declarative `profiles.ini` — not a browser-owned, version-unstable database. A separate one-time migration helper carries the existing `Work`/`Perso` data into the new `work`/`leisure` directories.

**Tech Stack:** chezmoi (Go text/template + Sprig), POSIX sh + Bash, Firefox 147+ (XDG base-dir support), sqlite3 (migration only).

## Global Constraints

- **XDG target path:** `~/.config/mozilla/firefox/` — Firefox 147+ uses this base **only when `~/.mozilla` does not exist**. Legacy `~/.mozilla` must be retired for XDG to take effect. (Confirmed: FF 152 on this machine.)
- **Classic `profiles.ini` only:** no `[Install…]` section, no `StoreID`. Profile identity is `IsRelative=1` + `Path=<id>`.
- **Selector disabled:** every profile's `user.js` sets `browser.profiles.enabled=false`. Switching is via `about:profiles`, `firefox -P <id>`, or the generated `.desktop` launchers.
- **Addons stay global:** the existing enterprise policy (`.chezmoidata/firefox_policies.json` → `/usr/lib/firefox/distribution/policies.json`) applies to all profiles (the union). Per-profile addon scoping is explicitly out of scope here (deferred "specifics" work).
- **Script standards:** `.chezmoiscripts/` output uses log templates (`log_start`, `log_step`, `log_success`, `log_skip`, `log_warning`, `log_complete`) — never bare `echo`. Bash scripts use `set -euo pipefail`.
- **Validation chain (this repo has no xUnit):** `chezmoi execute-template < file.tmpl` (renders Go template), pipe rendered shell to `shellcheck -`, `chezmoi cat <target>` / inspect generated output, `bash -n` / `sh -n` for syntax. A `.sh.tmpl` that passes `bash -n` on source can still render invalid shell — always validate **rendered** output.
- **Never write into a profile dir while Firefox is running** — the profile-management script warns; the migration script hard-refuses.
- **Commit after each task.**

---

## File Structure

| File | Responsibility | Action |
|------|----------------|--------|
| `.chezmoidata/firefox.yaml` | Single source of truth: profile list, default, common + per-profile prefs | Create |
| `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl` | Materialize profile dirs, `user.js`, `profiles.ini`, `.desktop` launchers from the data file | Create |
| `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox` | Symlink theme `userChrome.css` into **every** managed profile; XDG-first | Modify |
| `private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate` | One-time: carry existing `Work`/`Perso` data into `work`/`leisure`, retire `~/.mozilla`, strip selector prefs | Create |
| `.claude/rules/chezmoi-data.md` | Document the new `firefox.yaml` data file | Modify |

**Phasing:** Tasks 1–4 are the **portable declarative core** (safe on any machine, no data loss, works on a fresh install by creating three empty named profiles). Task 5 is the **one-time migration** of *this* machine's existing data. Task 6 is documentation. The hybrid alternative is described in an appendix, not implemented.

---

### Task 1: Firefox profile data file

**Files:**
- Create: `.chezmoidata/firefox.yaml`

**Interfaces:**
- Produces: template data `.firefox` with fields:
  - `.firefox.profile_root` (string, `$HOME`-relative) → `.config/mozilla/firefox`
  - `.firefox.default` (string) → profile `id` marked `Default=1`
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
# Firefox's new SQLite profile selector is disabled (browser.profiles.enabled=false)
# so all state stays declarative. Addons remain global via firefox_policies.json.

firefox:
  # XDG profile root, relative to $HOME. Firefox 147+ uses ~/.config/mozilla/firefox
  # when ~/.mozilla is absent.
  profile_root: ".config/mozilla/firefox"

  # Which profile id is marked Default=1 in profiles.ini (plain `firefox` launches it).
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

### Task 2: Profile-management run_onchange script

Creates profile directories, `user.js`, `profiles.ini`, and `.desktop` launchers from `firefox.yaml`. Idempotent and additive: it never deletes an existing profile directory, so it composes with the Task 5 migration (which pre-seeds `work`/`leisure`).

**Files:**
- Create: `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl`

**Interfaces:**
- Consumes: `.firefox.*` from Task 1.
- Produces (on disk): `~/.config/mozilla/firefox/<id>/user.js`, `~/.config/mozilla/firefox/profiles.ini`, `~/.local/share/applications/firefox-<id>.desktop`.

- [ ] **Step 1: Write the script template**

```bash
#!/usr/bin/env bash

# Script: run_onchange_after_manage_firefox_profiles.sh
# Purpose: Declaratively manage Firefox profiles (XDG): dirs, user.js, profiles.ini, launchers
# Requirements: Arch Linux, firefox

# Hash: {{ .firefox | toJson | sha256sum }}

{{ includeTemplate "log_start" "Managing Firefox profiles..." }}

set -euo pipefail

if ! command -v firefox >/dev/null 2>&1; then
    {{ includeTemplate "log_skip" "Firefox not installed, skipping" }}
    exit 0
fi

PROFILE_ROOT="$HOME/{{ .firefox.profile_root }}"
APP_DIR="$HOME/.local/share/applications"

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
{{ includeTemplate "log_step" "Writing profiles.ini..." }}
cat > "$PROFILE_ROOT/profiles.ini" <<'PROFILES_EOF'
[General]
StartWithLastProfile=1
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
{{ includeTemplate "log_step" "Generating per-profile launchers..." }}
rm -f "$APP_DIR"/firefox-*.desktop
{{ range .firefox.profiles }}
cat > "$APP_DIR/firefox-{{ .id }}.desktop" <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox — {{ .name }}
Comment=Browse the Web ({{ .name }} profile)
Exec=firefox -P {{ .id }} %U
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

Run: `chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl`
Expected: fully-rendered Bash. Confirm the `user.js` heredoc for `work` contains `user_pref("browser.profiles.enabled", false);` (unquoted `false`) and `user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);`, and that `profiles.ini` has three `[ProfileN]` blocks with `Default=1` only under `Path=work`.

- [ ] **Step 3: Lint the rendered shell**

Run: `chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl | shellcheck -`
Expected: no errors. (If shellcheck flags the heredoc bodies, they are data — acceptable; there should be no SC2xxx on the shell logic itself.)

- [ ] **Step 4: Dry-run apply and inspect real output**

Run: `chezmoi apply --dry-run --verbose .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl 2>&1 | head -40`
Expected: chezmoi reports it will run the script (hash changed). No error.

- [ ] **Step 5: Apply for real, then verify on disk**

Run:
```bash
chezmoi apply .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
ls -1 ~/.config/mozilla/firefox/          # expect: leisure/ profiles.ini ringstone/ work/ (+ any migrated data)
cat ~/.config/mozilla/firefox/profiles.ini
grep browser.profiles.enabled ~/.config/mozilla/firefox/work/user.js
ls -1 ~/.local/share/applications/firefox-*.desktop
```
Expected: three profile dirs each with `user.js`; `profiles.ini` valid with `Default=1` under work; `user_pref("browser.profiles.enabled", false);` present; three launcher files.

- [ ] **Step 6: Commit**

```bash
git add .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
git commit -m "Add run_onchange script to manage Firefox profiles declaratively"
```

---

### Task 3: Retarget theme-apply-firefox to XDG + all profiles

The current script targets one `*.default-release` profile in a legacy/`.config` probe order that no longer matches reality. Rewrite it to prefer the XDG root and symlink `userChrome.css` into **every** managed profile.

**Files:**
- Modify: `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox`

**Interfaces:**
- Consumes: `~/.config/themes/current/firefox-userChrome.css` (existing theme asset), profile dirs from Task 2.
- Produces: `~/.config/mozilla/firefox/<id>/chrome/userChrome.css` symlink per profile.

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

# XDG-first (Firefox 147+), then legacy fallback
if [ -d "$HOME/.config/mozilla/firefox" ]; then
    FIREFOX_DIR="$HOME/.config/mozilla/firefox"
elif [ -d "$HOME/.mozilla/firefox" ]; then
    FIREFOX_DIR="$HOME/.mozilla/firefox"
else
    exit 0
fi

# Symlink userChrome.css into every profile directory (identified by user.js or prefs.js)
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

Run: `shellcheck -s sh private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox`
Expected: no errors.

- [ ] **Step 4: Apply and verify symlinks exist for all profiles**

Run:
```bash
chezmoi apply private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
~/.local/bin/theme-apply-firefox 2>/dev/null || ~/.local/share/chezmoi/private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
ls -l ~/.config/mozilla/firefox/*/chrome/userChrome.css
```
Expected: a `userChrome.css` symlink under each profile's `chrome/` pointing into `~/.config/themes/current/`. (If no theme provides `firefox-userChrome.css`, script exits 0 silently — acceptable.)

- [ ] **Step 5: Commit**

```bash
git add private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
git commit -m "Retarget theme-apply-firefox to XDG and all managed profiles"
```

---

### Task 4: End-to-end verification of the declarative core

No new files — a gate confirming Tasks 1–3 compose correctly and Firefox actually adopts the profiles. Fold this verification into a single reviewable checkpoint.

**Files:** none (verification only).

- [ ] **Step 1: Full render/lint sweep**

Run:
```bash
chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl | shellcheck -
sh -n private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
chezmoi data | jaq '.firefox.profiles | length'   # expect 3
```
Expected: clean shellcheck, clean `sh -n`, `3`.

- [ ] **Step 2: Confirm Firefox lists the profiles (with Firefox closed)**

Run: `firefox -P` (opens the classic Profile Manager dialog) — **or**, non-interactively, inspect `about:profiles` after launch.
Expected: `work`, `leisure`, `ringstone` listed; `work` is default.

- [ ] **Step 3: Confirm the new selector is gone**

Launch `firefox -P work`, open a window.
Expected: **no** profile avatar button in the toolbar (the `browser.profiles.enabled=false` pref took effect). Visit `about:config`, search `browser.profiles.enabled` → `false` (user-set).

- [ ] **Step 4: Confirm launchers work**

Run: `gtk-launch firefox-leisure` (or select "Firefox — Perso" from Wofi).
Expected: Firefox opens the `leisure` profile (confirm via `about:profiles` showing leisure as current).

- [ ] **Step 5: Commit any doc/notes touched during verification**

```bash
git commit --allow-empty -m "Verify declarative Firefox profile core end-to-end"
```

---

### Task 5: One-time migration of existing Work/Perso data (this machine)

Carries the existing `Work` (`nb2l5vl7.default-release`) and `Perso` (`tPJagWwW.Profile 1`) data — history, logins, cookies — into `~/.config/mozilla/firefox/work` and `.../leisure`, retires `~/.mozilla` so Firefox switches to XDG, and strips the new-selector prefs for a clean classic break. Interactive and idempotent; refuses to run while Firefox is open. **Run this before the first `chezmoi apply` of Task 2 on this machine** (or after — Task 2 is additive and will simply fill `user.js`/`profiles.ini`/`ringstone` around the migrated dirs).

**Files:**
- Create: `private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate`

**Interfaces:**
- Consumes: `~/.mozilla/firefox/Profile Groups/<id>.sqlite` (name→dir map), existing profile dirs.
- Produces: `~/.config/mozilla/firefox/work`, `.../leisure`; a backup tarball; retired `~/.mozilla.migrated-<ts>`.

- [ ] **Step 1: Write the migration script**

```bash
#!/usr/bin/env bash

# Script: firefox-profiles-migrate
# Purpose: One-time migration of existing Firefox profiles into the XDG classic-declarative
#          layout (Work -> work, Perso -> leisure). Retires ~/.mozilla so Firefox adopts XDG.
# Requirements: Firefox closed, sqlite3 (for name mapping), bash

set -euo pipefail

LEGACY="$HOME/.mozilla"
LEGACY_FF="$LEGACY/firefox"
XDG_FF="$HOME/.config/mozilla/firefox"

log()  { printf '→ %s\n' "$1"; }
warn() { printf '⚠️  %s\n' "$1" >&2; }
die()  { printf '❌ %s\n' "$1" >&2; exit 1; }

# 1. Firefox must be closed
if pgrep -x firefox >/dev/null 2>&1; then
    die "Firefox is running. Close it completely, then re-run."
fi

# 2. Anything to migrate?
[ -d "$LEGACY_FF" ] || { log "No ~/.mozilla/firefox found — nothing to migrate."; exit 0; }

# 3. Full backup before touching anything
BACKUP="$HOME/.mozilla.pre-xdg-$(date +%Y%m%d%H%M%S).tar.zst"
log "Backing up ~/.mozilla -> $BACKUP"
tar --zstd -cf "$BACKUP" -C "$HOME" .mozilla

# 4. Map display names -> profile dirs via SelectableProfileService sqlite
declare -A NAME_TO_DIR=()
GROUP_DB="$(find "$LEGACY_FF/Profile Groups" -maxdepth 1 -name '*.sqlite' 2>/dev/null | head -1 || true)"
if [ -n "$GROUP_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
    while IFS='|' read -r pname ppath; do
        [ -n "$pname" ] && NAME_TO_DIR["$pname"]="$ppath"
    done < <(sqlite3 "$GROUP_DB" "SELECT name,path FROM Profiles;")
else
    warn "No group SQLite or sqlite3 missing — cannot auto-map names."
fi

mkdir -p "$XDG_FF"

move_profile() {  # $1 = legacy dir name, $2 = new id
    local src="$LEGACY_FF/$1" dst="$XDG_FF/$2"
    [ -n "$1" ] || { warn "No source dir for '$2' — skipping (create fresh via chezmoi apply)."; return; }
    [ -d "$src" ] || { warn "Source '$1' not found — skipping '$2'."; return; }
    [ -e "$dst" ] && { warn "Target '$dst' already exists — skipping '$2'."; return; }
    mv "$src" "$dst"
    # Strip new-selector linkage for a clean classic break (Firefox is closed)
    if [ -f "$dst/prefs.js" ]; then
        sed -i '/browser\.profiles\./d; /toolkit\.profiles\.storeID/d' "$dst/prefs.js"
    fi
    log "Migrated '$1' -> $2"
}

# 5. Perform the known mappings
move_profile "${NAME_TO_DIR[Work]:-}"  work
move_profile "${NAME_TO_DIR[Perso]:-}" leisure

# 6. Retire ~/.mozilla so Firefox switches to the XDG base
mv "$LEGACY" "$HOME/.mozilla.migrated-$(date +%Y%m%d%H%M%S)"
log "Retired ~/.mozilla (Firefox will now use ~/.config/mozilla)."

printf '\n✅ Migration done. Next:\n  chezmoi apply\n(to write user.js/profiles.ini, create the ringstone profile, and launchers)\n'
```

- [ ] **Step 2: Syntax + lint**

Run:
```bash
bash -n private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
shellcheck private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
```
Expected: no syntax errors; shellcheck clean (associative array + process substitution require the `#!/usr/bin/env bash` shebang, which is present).

- [ ] **Step 3: Apply the script into place**

Run: `chezmoi apply private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate`
Expected: `~/.local/lib/scripts/utils/firefox-profiles-migrate` exists and is executable (`-rwxr-xr-x`).

- [ ] **Step 4: Execute the migration (destructive — backup is automatic)**

> Close Firefox first. This moves live browsing data.

Run: `~/.local/lib/scripts/utils/firefox-profiles-migrate`
Expected: prints backup path, "Migrated … -> work", "Migrated … -> leisure", "Retired ~/.mozilla". Then:
```bash
ls -1 ~/.config/mozilla/firefox/            # work/ leisure/ present (with real data)
test ! -e "$HOME/.mozilla" && echo "legacy retired OK"
```

- [ ] **Step 5: Fill declarative state around the migrated dirs**

Run:
```bash
chezmoi apply .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
grep browser.profiles.enabled ~/.config/mozilla/firefox/work/user.js   # present
ls -d ~/.config/mozilla/firefox/ringstone                              # created fresh
firefox -P   # confirm work (with your history), leisure, ringstone all listed
```
Expected: `work`/`leisure` retain data; `ringstone` is new and empty; selector disabled; all three in the Profile Manager.

- [ ] **Step 6: Commit**

```bash
git add private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate
git commit -m "Add one-time Firefox Work/Perso -> XDG classic profile migration helper"
```

---

### Task 6: Document the data file

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

## Appendix: The "Hybrid" Alternative (not implemented)

This plan implements **classic declarative** — the robust path that gives up Firefox's new in-app avatar/theme profile switcher in exchange for zero coupling to a browser-owned, version-unstable SQLite schema. If the in-app avatar switcher turns out to be a must-have, the **hybrid (reconcile)** approach is the fallback. It is documented here so the decision — and its cost — stays visible.

**What it adds over this plan:**

- **Keep** `browser.profiles.enabled=true` (drop that line from `common_prefs`).
- **Do not** write `profiles.ini` by hand. Instead, let Firefox bootstrap a profile *group* once (its `StoreID`, group UUIDs, schema migrations, and `Profile Groups/<StoreID>.sqlite` all created by Firefox — never authored by us).
- Add a **reconcile step** (Firefox closed, WAL checkpointed) that opens the existing `Profile Groups/<StoreID>.sqlite` and `INSERT`/`UPDATE`s **only** the 7-column `Profiles` table (`id, path, name, avatar, themeId, themeFg, themeBg`) so its rows match `firefox.yaml` — pointing `path` at the same `work`/`leisure`/`ringstone` dirs this plan creates. `avatar`/`themeId`/`themeFg`/`themeBg` become new per-profile fields in `firefox.yaml`.

**Why it is the fallback, not the default:**

- The `SelectableProfileService` schema is new (~FF 140), undocumented, and evolving — a Firefox update can change it and silently break the reconcile step.
- Identity is spread across `profiles.ini` (`StoreID`), `installs.ini`, the SQLite filename, and per-profile prefs (`toolkit.profiles.storeID`, `browser.profiles.*`, group UUIDs in `SharedPrefs`). We would only safely own the `Profiles` table; the rest must remain Firefox-managed.
- It requires Firefox fully closed on every apply (WAL lock), versus this plan where only `profiles.ini` edits benefit from a closed browser and `user.js` is always safe.

**Migration under hybrid:** the Task 5 helper would **not** strip `browser.profiles.*`/`toolkit.profiles.storeID`, and would **not** delete `Profile Groups/` — it would keep Firefox's group intact and let the reconcile step rewrite the `Profiles` rows to the new dir names.

If this fallback is ever chosen, it is a separate spec/plan cycle: it changes Task 1 (add avatar/theme fields), replaces Task 2's `profiles.ini` generation with a reconcile script, and alters Task 5's teardown.

---

## Self-Review

**Spec coverage** (against the brainstorm decisions):
- Three profiles `work`/`leisure`/`ringstone` → Task 1 data, Task 2 materialization. ✅
- Context separation (distinct cookies/logins/history) → inherent to separate profile dirs; migration preserves existing data (Task 5). ✅
- Privacy secondary → `common_prefs` scaffolding + global enterprise policy retained (Global Constraints); per-profile privacy prefs are data-file additions, deferred by user request. ✅
- XDG target `~/.config/mozilla/firefox` → Global Constraints + Tasks 2/3/5. ✅
- Classic declarative (selector disabled, `profiles.ini` authored) → Task 2 + `browser.profiles.enabled=false`. ✅
- Map existing Work→work, Perso→leisure → Task 5 (sqlite name map + `move_profile`). ✅
- In-Firefox / launcher switching → Task 2 `.desktop` launchers + `about:profiles`/`firefox -P` (Task 4 verify). ✅
- Fix the dead `.config/mozilla` probe in theme script → Task 3. ✅
- Mention hybrid alternative → Appendix. ✅

**Placeholder scan:** No `TBD`/`TODO`/"handle edge cases". Empty `prefs: []` is a concrete valid state (deferred specifics), not a placeholder — every step ships runnable content. ✅

**Type/name consistency:** `.firefox.profile_root`, `.firefox.default`, `.firefox.common_prefs[].{key,value}`, `.firefox.profiles[].{id,name,prefs}` used identically in Tasks 1–2; profile ids `work`/`leisure`/`ringstone` consistent across data, script, theme loop, launchers, and migration targets; `move_profile <legacyDir> <newId>` matches its two call sites. ✅
