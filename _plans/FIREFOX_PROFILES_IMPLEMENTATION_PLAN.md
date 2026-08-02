# Firefox Multi-Profile (Classic Declarative) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage three Firefox profiles (`work`, `leisure`, `ringstone`) declaratively from a single chezmoi data file, targeting Firefox's XDG profile location, with per-profile `user.js`, a generated `profiles.ini`, per-profile theme `userChrome.css`, and per-profile `.desktop` launchers.

**Architecture:** A new `.chezmoidata/firefox.yaml` is the single source of truth. A hash-triggered `run_onchange` chezmoi-template script ranges over that data to create each profile directory under `~/.config/mozilla/firefox/`, write its `user.js`, generate a classic `profiles.ini`, and emit per-profile launchers. The existing `theme-apply-firefox` script is retargeted to XDG and loops over every managed profile. Firefox's new SQLite-backed profile selector (`SelectableProfileService`) is deliberately disabled (`browser.profiles.enabled=false`) so all profile identity lives in the declarative `profiles.ini` — not a browser-owned, version-unstable database. Firefox's *per-install dedicated profile* mechanism is likewise disabled session-wide (`MOZ_LEGACY_PROFILES=1`) so the authored `Default=1` is authoritative. A separate one-time migration helper carries the existing `Work`/`Perso` data into the new `work`/`leisure` directories.

**Tech Stack:** chezmoi (Go text/template + Sprig), POSIX sh + Bash, Firefox 147+ (XDG base-dir support), sqlite3 (migration only).

## Global Constraints

- **XDG target path:** `~/.config/mozilla/firefox/` — both `profiles.ini` **and** the profile directories live here (verified empirically on Firefox 153.0.1; `XDG_DATA_HOME` is *not* used for profiles).
- **Legacy takes precedence over XDG, and the trigger is `~/.mozilla/firefox` — not `~/.mozilla`.** Verified: an empty `~/.mozilla` still yields XDG; creating `~/.mozilla/firefox` flips Firefox back to legacy. So retiring the `firefox` subdirectory alone is sufficient, and `~/.mozilla/extensions` can be left in place.
- **`MOZ_LEGACY_PROFILES=1` is mandatory.** Without it Firefox ignores `Default=1` entirely: it applies per-install dedicated profiles, creates its own `*.default-release`, binds it via an `[Install<HASH>]` section, writes `installs.ini`, and leaves the managed profiles unused. Verified both ways on Firefox 153.0.1. With the variable set, Firefox honours `Default=1` and leaves `profiles.ini` byte-identical.
- **Classic `profiles.ini` only:** no `[Install…]` section, no `StoreID`. Profile identity is `IsRelative=1` + `Path=<id>`.
- **Selector disabled:** every profile's `user.js` sets `browser.profiles.enabled=false`. Switching is via `about:profiles`, `firefox -P <id>`, or the generated `.desktop` launchers.
- **Migration strictly precedes profile management.** The `run_onchange` script refuses to run while `~/.mozilla/firefox` exists, because creating the XDG target dirs first would make the migration refuse to move real data. Task 3 before Task 4, enforced in code.
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
| `private_dot_config/hypr/conf/environment.conf` | Session env var `MOZ_LEGACY_PROFILES=1` (live Hyprland config) | Modify |
| `private_dot_config/hypr/conf/environment.lua` | Same var in the parallel Lua config (kept in sync with `.conf`) | Modify |
| `private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate` | One-time: carry existing `Work`/`Perso` data into `work`/`leisure`, retire `~/.mozilla/firefox`, strip selector prefs | Create |
| `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl` | Materialize profile dirs, `user.js`, `profiles.ini`, `.desktop` launchers from the data file | Create |
| `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox` | Symlink theme `userChrome.css` into **every** managed profile; XDG-first | Modify |
| `.claude/rules/chezmoi-data.md` | Document the new `firefox.yaml` data file | Modify |

**Phasing and ordering:** Task 1 (data) and Task 2 (env var) are inert prerequisites. **Task 3 (migration) must complete before Task 4 (profile management)** — Task 4 enforces this itself via an interlock. Task 5 is theming, Task 6 a human verification gate, Task 7 documentation. The hybrid alternative is described in an appendix, not implemented.

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
# Requires MOZ_LEGACY_PROFILES=1 in the session environment, otherwise Firefox
# ignores Default=1 and creates its own per-install dedicated profile.
# Firefox's new SQLite profile selector is disabled (browser.profiles.enabled=false)
# so all state stays declarative. Addons remain global via firefox_policies.json.

firefox:
  # XDG profile root, relative to $HOME. Firefox uses ~/.config/mozilla/firefox
  # when ~/.mozilla/firefox is absent.
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

### Task 2: Session environment variable `MOZ_LEGACY_PROFILES=1`

Without this variable the entire declarative approach silently fails — Firefox ignores the authored `Default=1`, creates a `*.default-release` profile of its own, and binds it with an `[Install<HASH>]` section. This must land **before** any `profiles.ini` is authored.

`environment.conf` is the live config (`~/.config/hypr/hyprland.conf` sources it); `environment.lua` is the parallel Lua port kept in sync. Both carry `MOZ_ENABLE_WAYLAND`, so both get this too.

**Files:**
- Modify: `private_dot_config/hypr/conf/environment.conf`
- Modify: `private_dot_config/hypr/conf/environment.lua`

**Interfaces:**
- Produces: `MOZ_LEGACY_PROFILES=1` in the Hyprland session environment, inherited by every app launched from the session (Wofi, launchers, terminals).

- [ ] **Step 1: Add the variable to `environment.conf`**

Find this existing block:

```
# Force Firefox to use native Wayland (better performance than XWayland)
env = MOZ_ENABLE_WAYLAND,1
```

Add immediately after it:

```
# Make the managed profiles.ini authoritative: honour Default=1 instead of
# Firefox's per-install dedicated profiles, which ignore it and create their own
# *.default-release + [Install<HASH>] binding.
env = MOZ_LEGACY_PROFILES,1
```

- [ ] **Step 2: Add the same variable to `environment.lua`**

Find this existing line:

```lua
-- Force Firefox to use native Wayland (better performance than XWayland)
hl.env("MOZ_ENABLE_WAYLAND", "1")
```

Add immediately after it:

```lua
-- Make the managed profiles.ini authoritative: honour Default=1 instead of
-- Firefox's per-install dedicated profiles, which ignore it and create their own
-- *.default-release + [Install<HASH>] binding.
hl.env("MOZ_LEGACY_PROFILES", "1")
```

- [ ] **Step 3: Apply and verify the rendered target**

Run:
```bash
chezmoi apply ~/.config/hypr/conf/environment.conf
grep MOZ_LEGACY_PROFILES ~/.config/hypr/conf/environment.conf
```
Expected: `env = MOZ_LEGACY_PROFILES,1`

- [ ] **Step 4: Load it into the running session**

Run: `hyprctl reload`
Expected: `ok`. Note that `env` in Hyprland applies to **newly launched** processes only; already-running apps keep the old environment. A full logout/login guarantees it everywhere.

Verify with a freshly spawned process:
```bash
hyprctl dispatch exec 'sh -c "echo $MOZ_LEGACY_PROFILES > /tmp/mlp.txt"'
sleep 1 && cat /tmp/mlp.txt
```
Expected: `1`. If empty, log out and back in before continuing to Task 3.

- [ ] **Step 5: Lint the Lua**

Run: `mise run lint:lua`
Expected: stylua reports no diff for `environment.lua`.

- [ ] **Step 6: Commit**

```bash
git add private_dot_config/hypr/conf/environment.conf private_dot_config/hypr/conf/environment.lua
git commit -m "Set MOZ_LEGACY_PROFILES=1 so the managed Firefox profiles.ini is authoritative"
```

---

### Task 3: One-time migration of existing Work/Perso data (this machine)

Carries the existing `Work` (`nb2l5vl7.default-release`) and `Perso` (`tPJagWwW.Profile 1`) data — history, logins, cookies — into `~/.config/mozilla/firefox/work` and `.../leisure`, retires `~/.mozilla/firefox` so Firefox switches to XDG, and strips the new-selector prefs for a clean classic break.

**This must run before Task 4.** Task 4 creates the XDG target directories; once they exist this script refuses to overwrite them, and the real browsing data would be stranded in the legacy tree.

The script is fail-safe by construction: it only retires the legacy tree if at least one profile actually moved, and it aborts rather than skipping when a target already exists.

**Files:**
- Create: `private_dot_local/lib/scripts/utils/executable_firefox-profiles-migrate`

**Interfaces:**
- Consumes: `~/.mozilla/firefox/Profile Groups/<id>.sqlite` (name→dir map), existing profile dirs.
- Produces: `~/.config/mozilla/firefox/work`, `.../leisure`; a backup tarball; retired `~/.mozilla/firefox.migrated-<ts>`.

> **Verified precondition:** on this machine `sqlite3 -readonly "$HOME/.mozilla/firefox/Profile Groups/3bfda0e8.sqlite" "SELECT name,path FROM Profiles;"` returns exactly `Work|nb2l5vl7.default-release` and `Perso|tPJagWwW.Profile 1`.

- [ ] **Step 1: Write the migration script**

```bash
#!/usr/bin/env bash

# Script: firefox-profiles-migrate
# Purpose: One-time migration of existing Firefox profiles into the XDG classic-declarative
#          layout (Work -> work, Perso -> leisure). Retires ~/.mozilla/firefox so Firefox
#          adopts the XDG base dir.
# Requirements: Firefox closed, sqlite3 (for name mapping), bash

set -euo pipefail

LEGACY_FF="$HOME/.mozilla/firefox"
XDG_FF="$HOME/.config/mozilla/firefox"
TS="$(date +%Y%m%d%H%M%S)"

log()  { printf '→ %s\n' "$1"; }
warn() { printf '⚠️  %s\n' "$1" >&2; }
die()  { printf '❌ %s\n' "$1" >&2; exit 1; }

# 1. Firefox must be closed — moving a live profile corrupts it.
if pgrep -x firefox >/dev/null 2>&1; then
    die "Firefox is running. Close it completely, then re-run."
fi

# 2. Anything to migrate?
[ -d "$LEGACY_FF" ] || { log "No ~/.mozilla/firefox found — nothing to migrate."; exit 0; }

# 3. Full backup before touching anything.
BACKUP="$HOME/.mozilla-firefox.pre-xdg-$TS.tar.zst"
log "Backing up ~/.mozilla/firefox -> $BACKUP"
tar --zstd -cf "$BACKUP" -C "$HOME/.mozilla" firefox

# 4. Map display names -> profile dirs via the SelectableProfileService sqlite.
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

# 6. Only retire the legacy tree if something actually moved.
[ "$MOVED" -gt 0 ] || die "No profiles were migrated — leaving ~/.mozilla/firefox untouched. Backup: $BACKUP"

# Renaming the 'firefox' subdir is sufficient: Firefox selects the legacy base on
# the existence of ~/.mozilla/firefox, not ~/.mozilla. This preserves
# ~/.mozilla/extensions and any other sibling data.
mv "$LEGACY_FF" "$HOME/.mozilla/firefox.migrated-$TS"
log "Retired ~/.mozilla/firefox (Firefox will now use ~/.config/mozilla)."

printf '\n✅ Migrated %s profile(s). Next:\n  chezmoi apply\n(to write user.js/profiles.ini, create the ringstone profile, and launchers)\n' "$MOVED"
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
→ Backing up ~/.mozilla/firefox -> /home/amaury/.mozilla-firefox.pre-xdg-<ts>.tar.zst
→ Discovered 2 profile name(s): Work Perso
→ Migrated 'Work' -> work
→ Migrated 'Perso' -> leisure
→ Retired ~/.mozilla/firefox (Firefox will now use ~/.config/mozilla).

✅ Migrated 2 profile(s). Next:
  chezmoi apply
```

Then verify:
```bash
ls -1 ~/.config/mozilla/firefox/          # work/ leisure/ present, with real data
ls -1 ~/.mozilla/                         # extensions/ preserved, firefox.migrated-<ts>/
test ! -e "$HOME/.mozilla/firefox" && echo "legacy retired OK"
grep -c 'browser.profiles' ~/.config/mozilla/firefox/work/prefs.js   # expect 0
```

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
- Produces (on disk): `~/.config/mozilla/firefox/<id>/user.js`, `~/.config/mozilla/firefox/profiles.ini`, `~/.local/share/applications/firefox-<id>.desktop`.

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
# Default=1 is only authoritative under MOZ_LEGACY_PROFILES=1. Without it Firefox
# uses per-install dedicated profiles: it ignores Default=1, creates its own
# *.default-release, and binds it via an [Install<HASH>] section.
if [ -f "$PROFILE_ROOT/profiles.ini" ] && grep -q '^\[Install' "$PROFILE_ROOT/profiles.ini"; then
    {{ includeTemplate "log_warning" "profiles.ini has an [Install] section — Firefox ran without MOZ_LEGACY_PROFILES=1. Check the session environment; a stray *.default-release profile may exist." }}
fi

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
# Exec carries MOZ_LEGACY_PROFILES inline so a launcher works even if the session
# environment is missing it (e.g. launched from a non-Hyprland context).
{{ includeTemplate "log_step" "Generating per-profile launchers..." }}
rm -f "$APP_DIR"/firefox-*.desktop
{{ range .firefox.profiles }}
cat > "$APP_DIR/firefox-{{ .id }}.desktop" <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox — {{ .name }}
Comment=Browse the Web ({{ .name }} profile)
Exec=env MOZ_LEGACY_PROFILES=1 firefox -P {{ .id }} %U
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
Expected: exit 0. Confirm in the output that the `user.js` heredoc for `work` contains `user_pref("browser.profiles.enabled", false);` (unquoted `false`) and `user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);`, and that the `profiles.ini` heredoc has three `[ProfileN]` blocks with `Default=1` appearing only under `Path=work`.

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
ls -1 ~/.local/share/applications/firefox-*.desktop
```
Expected: three profile dirs each with `user.js`; `profiles.ini` valid with `Default=1` under `Path=work`; `user_pref("browser.profiles.enabled", false);` present; three launcher files.

- [ ] **Step 6: Commit**

```bash
git add .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
git commit -m "Add run_onchange script to manage Firefox profiles declaratively"
```

---

### Task 5: Retarget theme-apply-firefox to XDG + all profiles

The current script targets one `*.default-release` profile in a probe order that no longer matches reality. Rewrite it to prefer the XDG root and symlink `userChrome.css` into **every** managed profile.

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
Expected: `Work`, `Perso`, `Ringstone` listed; `Work` is default.

- [ ] **Step 3: Confirm plain `firefox` lands on `work` and creates nothing**

Run: `firefox` (no arguments), then visit `about:profiles`.
Expected: the current profile is the one rooted at `~/.config/mozilla/firefox/work`, with your existing history and logins. Then, with Firefox closed again:

```bash
ls -1 ~/.config/mozilla/firefox/        # exactly: work leisure ringstone (+ Crash Reports, Pending Pings, profiles.ini)
grep -c '^\[Install' ~/.config/mozilla/firefox/profiles.ini   # expect 0
test ! -e ~/.config/mozilla/firefox/installs.ini && echo "no installs.ini — MOZ_LEGACY_PROFILES is working"
```
Expected: no stray `*.default-release` directory, no `[Install…]` section, no `installs.ini`. Any of those appearing means `MOZ_LEGACY_PROFILES=1` did not reach Firefox — revisit Task 2 step 4.

- [ ] **Step 4: Confirm the selector is gone and launchers work**

Launch `firefox -P work`. Expected: **no** profile avatar button in the toolbar; `about:config` shows `browser.profiles.enabled` = `false` (user-set).

Run: `gtk-launch firefox-leisure` (or pick "Firefox — Perso" in Wofi).
Expected: Firefox opens the `leisure` profile (confirm via `about:profiles`).

- [ ] **Step 5: Record the verification**

```bash
git commit --allow-empty -m "Verify declarative Firefox profile core end-to-end"
```

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

| Claim | Result |
|---|---|
| XDG profile root | Profile dirs **and** `profiles.ini` both under `$XDG_CONFIG_HOME/mozilla/firefox`. `XDG_DATA_HOME` is not used for profiles. |
| Legacy trigger | `~/.mozilla/firefox`, **not** `~/.mozilla`. An empty `~/.mozilla` still yields XDG. |
| `Default=1` alone | **Ignored.** Firefox created its own `vrte1071.default-release`, added `[Install4F96D1932A9F858E]` + `installs.ini`, left the managed profiles untouched. |
| `Default=1` + `MOZ_LEGACY_PROFILES=1` | **Honoured.** Managed profile used, no stray profile, `profiles.ini` left byte-identical. |
| `[Install<HASH>]` written by hand | Also works, but `HASH` is derived from the installation directory — machine/path specific, and unavailable on a fresh install. Rejected in favour of the env var. |
| Profile-group SQLite | `Profiles` table is 7 columns (`id, path, name, avatar, themeId, themeFg, themeBg`); `SELECT name,path` yields `Work|nb2l5vl7.default-release`, `Perso|tPJagWwW.Profile 1`. |

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
- Classic declarative (selector disabled, `profiles.ini` authored, `Default=1` authoritative) → Task 2 + Task 4 + `browser.profiles.enabled=false`. ✅
- Map existing Work→work, Perso→leisure → Task 3 (sqlite name map + `move_profile`). ✅
- In-Firefox / launcher switching → Task 4 `.desktop` launchers + `about:profiles`/`firefox -P` (Task 6 verify). ✅
- Fix the dead profile probe in the theme script → Task 5. ✅
- Mention hybrid alternative → Appendix B. ✅

**Placeholder scan:** No `TBD`/`TODO`/"handle edge cases". Empty `prefs: []` is a concrete valid state (deferred specifics), not a placeholder — every step ships runnable content. ✅

**Type/name consistency:** `.firefox.profile_root`, `.firefox.default`, `.firefox.common_prefs[].{key,value}`, `.firefox.profiles[].{id,name,prefs}` used identically in Tasks 1 and 4; profile ids `work`/`leisure`/`ringstone` consistent across data, script, theme loop, launchers, and migration targets; `move_profile <displayName> <newId>` matches its two call sites (note: takes the *display name*, and resolves the directory through `NAME_TO_DIR` internally). ✅

**Ordering consistency:** Task 3 (migration) precedes Task 4 (management) in numbering, in the File Structure phasing note, in the Global Constraints, and is enforced at runtime by Task 4's interlock plus Task 3's non-empty-target refusal. ✅

**Command correctness:** every `chezmoi apply` in this plan names a target path under `$HOME`; the `.chezmoiscripts/` entry is exercised via `chezmoi execute-template` + `bash` because it has no target path. ✅
