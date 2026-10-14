# Firefox Multi-Profile (Classic Declarative) Implementation Plan

> **Status (2026-10-14): NOT EXECUTED.** Nothing in Tasks 0–9 has been run. The plan was drafted July–August against Firefox 153 and reconciled on 2026-10-10. It was rewritten on 2026-10-14 after the machine was **reinstalled** and the design grew (see "What changed"). Live state that day, read-only:
>
> - `~/.mozilla` does not exist. Firefox **157.0.1** already uses `~/.config/mozilla/firefox/`.
> - Real data: `aybu1fna.default-release-1791981860338` (198 MB, in use). Stubs: `szhidnbj.default-release` (0 B), `ylj1j4gt.default` (4 KB).
> - Firefox wrote `installs.ini` and `[Install4F96D1932A9F858E] Locked=1` by itself. This is an in-situ confirmation, on 157, that per-install dedicated profiles still take over without `MOZ_LEGACY_PROFILES=1`.
> - `Profile Groups/` holds two sqlite DBs with no `Profiles` rows.
> - `chassisType` is `desktop`. `xdg-mime query default x-scheme-handler/https` is `firefox.desktop` (the EGL override).
>
> **What changed from the 2026-10-10 version:** the legacy-tree migration script is gone (Task 3 is now a few manual commands); profiles are chassis-gated; each profile gets its own window identity, Hyprland workspace and theme-coloured border; a link/launch chooser (`firefox-open`) becomes the `firefox.desktop` entry point; MerciApp is blocked (Task 0).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage Firefox profiles declaratively from a single chezmoi data file, targeting Firefox's XDG profile location, with per-profile `user.js`, a generated `profiles.ini`, per-profile theme `userChrome.css`, per-profile `.desktop` launchers, a chooser that routes links and plain launches, and per-profile Hyprland identity (workspace + border colour).

| Chassis | Profiles |
|---|---|
| desktop | `work`, `ringstone` |
| laptop | `work`, `leisure`, `ringstone` |

**Architecture:** `.chezmoidata/firefox.yaml` is the single source of truth. A shared include (`.chezmoitemplates/firefox_profiles`) computes the chassis-filtered profile ids and validates `default`; every consumer ranges over `.firefox.profiles` and keeps only those ids. Consumers:

1. a hash-triggered `run_onchange` script: profile dirs, `user.js`, `profiles.ini`, `.desktop` launchers;
2. `firefox-open`: the chooser behind `firefox.desktop` (links and plain launches);
3. `conf.d/firefox-profiles.lua`: Hyprland workspace and border rules;
4. `theme-apply-firefox`: loops over every managed profile.

Firefox's SQLite-backed profile selector (`SelectableProfileService`) is disabled (`browser.profiles.enabled=false`) so profile identity stays in the declarative `profiles.ini`. Per-install dedicated profiles are disabled session-wide (`MOZ_LEGACY_PROFILES=1`); that is what makes the classic Profile Manager reachable at all.

**Selection model — three entry points, split by intent:**

| Entry | Behaviour |
|---|---|
| Link (any URL/file argument), e.g. `xdg-open` | `firefox-open` sends it to the **last-focused** `firefox-<id>` window's profile; none running → `firefox.default`. Never prompts |
| Plain launch (`firefox.desktop`, launcher, no URL) | `firefox-open` shows the Quickshell menu (`quickshell-menu --json`) |
| Per-profile `.desktop` launcher / `firefox -P <id>` | straight to that profile |
| Bare `firefox` in a terminal | classic Profile Manager (`StartWithLastProfile=0`), `Default=1` preselected |

**Tech Stack:** chezmoi (Go text/template + Sprig), POSIX sh + Bash, Firefox 157 (XDG base-dir support), Hyprland Lua config, `jaq`, `quickshell-menu`.

## Global Constraints

- **XDG target path:** `~/.config/mozilla/firefox/` — both `profiles.ini` **and** the profile directories live here (verified on Firefox 153.0.1; `XDG_DATA_HOME` is not used for profiles; 157 uses the same root on this machine today).
- **Legacy takes precedence over XDG, and the trigger is `~/.mozilla/firefox` — not `~/.mozilla`.** Verified on 153: an empty `~/.mozilla` still yields XDG; creating `~/.mozilla/firefox` flips Firefox back to legacy. It does not exist on this machine now, but a laptop that predates the reinstall may still have one, so Task 4 keeps an interlock.
- **`MOZ_LEGACY_PROFILES=1` is mandatory — and its purpose is broader than `Default=1`.** Without it Firefox applies per-install dedicated profiles: it auto-creates its own `*.default-release`, binds it with an `[Install<HASH>]` section, writes `installs.ini`, and leaves the managed profiles unused. That bypasses `Default=1` and the Profile Manager alike. This machine currently shows exactly that state. Verified both ways on 153.0.1; the unmanaged state is observed on 157.0.1.
- **Every launch path goes through the EGL wrapper.** `~/.local/bin/firefox` (`private_dot_local/bin/executable_firefox`) is mandatory on this NVIDIA machine: bare `/usr/lib/firefox/firefox` starts but never maps a window. Anything this plan generates that launches Firefox must name the wrapper by absolute path — the per-profile `.desktop` files and `firefox-open`. The wrapper falls back to **XWayland** when the patched egl-wayland2 build is missing (fresh laptop before the build script runs); window identity must survive that (Task 2 gate).
- **The wrapper resolves `PATCHED_LIB` from `$HOME`.** Any test that overrides `$HOME` must symlink `$HOME/.local/lib` into the throwaway home, or the wrapper silently drops to XWayland and the test measures the wrong backend.
- **Isolation needs the XDG variables too.** The session exports `XDG_CONFIG_HOME`, which Firefox honours before `$HOME`; overriding `$HOME` alone silently runs against the real profile root (it happened). Override `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_DATA_HOME`, and `env -u BASH_ENV`.
- **Window identity is two flags, and remoting needs a profile (gate, 2026-10-14).** Every Firefox launch this plan generates passes `--name firefox-<id> --class firefox-<id> -P "<Name>"`. `--name` sets the class on Wayland only and `--class` on XWayland only; remoting routes by *profile*, so a launch without a profile flag lands in the wrong instance. `-P` matches the `Name=` in `profiles.ini` (case-sensitive), never the directory: a miss silently opens a Profile Manager. Profile `name`s must be single words.
- **Session env is uwsm, not Hyprland.** `MOZ_LEGACY_PROFILES=1` goes in `private_dot_config/uwsm/env.tmpl`. Anything set via `hl.env()` never reaches `quickshell.service` or the apps its launcher spawns. `hypr/conf/environment.lua` is a deliberately empty stub — do not touch it.
- **Classic `profiles.ini` only:** no `[Install…]` section, no `StoreID`. Profile identity is `IsRelative=1` + `Path=<id>`.
- **New SQLite selector disabled:** every profile's `user.js` sets `browser.profiles.enabled=false`. Switching is via `firefox-open`, `about:profiles`, `firefox -P <id>`, or the generated launchers.
- **Adoption strictly precedes profile management.** Task 4's script refuses to run while an unmanaged profile (a dir with `prefs.js` whose name is not a managed id) or `installs.ini` exists, because writing `profiles.ini` first would orphan the real data. Task 3 before Task 4.
- 🚨 **A `run_onchange` that exits 0 on its interlock is recorded as done and is not retried** until its rendered content changes. If Task 4's interlock fires, run the rendered script by hand once the cause is fixed (Task 4 Step 4). A `chezmoi apply` between committing Task 4 and finishing Task 3 burns the one-shot.
- **Task 5 (theming) depends on Tasks 3 and 4 and must NOT be parallelized with them.** If it runs first it matches nothing and exits 0 silently — indistinguishable from success. Tasks 6 and 7 depend on the Task 2 gate result. Tasks 0 and 1 are independent of the rest.
- **Addons stay global:** the enterprise policy (`.chezmoidata/firefox_policies.json` → `/usr/lib/firefox/distribution/policies.json`) applies to every profile. Per-profile addon scoping is out of scope.
- **Chassis filtering is in the consumers, not the data.** Data files are inert (`.claude/rules/chezmoi-data.md`). Inside a `range`, `.` is the profile: use `$.chassisType`, `$.firefox.default`, and Sprig's `has` takes the **needle first** (`has .id $ff.ids`).
- **Script standards:** `.chezmoiscripts/` output uses log templates — never bare `echo`. Bash scripts use `set -euo pipefail`. Use `[ ]` not `[[ ]]` (`.shellcheckrc` pins `severity=warning`, so SC2292 is filtered).
- **`chezmoi apply` takes TARGET paths, never source paths.** Entries under `.chezmoiscripts/` have no target path and cannot be applied selectively; test them by rendering to a file and running it.
- **Validation chain (no xUnit here):** `chezmoi execute-template < file.tmpl`, pipe rendered shell to `shellcheck --severity=warning`, inspect generated output, `bash -n` / `sh -n`. A `.sh.tmpl` that passes `bash -n` on source can still render invalid shell — always validate **rendered** output.
- **Never write into a profile dir while Firefox is running.**
- **Commit after each task.**

---

## File Structure

| File | Responsibility | Action |
|------|----------------|--------|
| `.chezmoidata/firefox_policies.json` | Block the MerciApp extension | Modify (Task 0) |
| `.chezmoidata/firefox.yaml` | Single source of truth: profiles, chassis, identity, workspace, default, prefs | Create |
| `.chezmoitemplates/firefox_profiles` | Chassis-filtered profile ids + `default`, as JSON; fails if `default` is not in the set | Create |
| `private_dot_config/uwsm/env.tmpl` | Session env var `MOZ_LEGACY_PROFILES=1` | Modify |
| `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl` | Profile dirs, `user.js`, `profiles.ini`, `.desktop` launchers | Create |
| `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox` | Symlink theme `userChrome.css` into every managed profile; XDG-first | Modify |
| `private_dot_local/lib/scripts/desktop/executable_firefox-open.tmpl` | Chooser: link → last-focused profile; plain launch → menu | Create |
| `.chezmoiscripts/run_onchange_after_configure_firefox_egl_workaround.sh.tmpl` | Route three of the four `firefox.desktop` `Exec=` lines to `firefox-open` | Modify |
| `private_dot_config/hypr/conf.d/firefox-profiles.lua.tmpl` | Per-profile workspace + identity border rules | Create |
| `.claude/rules/chezmoi-data.md`, `.claude/rules/chezmoi-templates.md` | Document the data file and the include | Modify |

**Ordering:** `0 → 1 ∥ 2(gate) → 3 → 4 → 5 → 6 → 7 → 8 → 9`. Tasks 6 and 7 depend on the Task 2 gate result (passed 2026-10-14: both flags, `-P "<Name>"`).

**Rollback (after Task 3):**

```bash
rm -rf ~/.config/mozilla/firefox
mv ~/.config/mozilla/firefox.backup-<ts> ~/.config/mozilla/firefox
```

The backup is a btrfs reflink clone taken before anything is touched. It sits **beside** the profile root, never inside it.

---

### Task 0: Block the MerciApp extension

**Files:**
- Modify: `.chezmoidata/firefox_policies.json`

`normal_installed` never uninstalls, so deleting the entry would leave MerciApp in the adopted `work` profile. `blocked` is expected to uninstall it from every profile and prevent reinstalling; confirm that in Step 3.

- [ ] **Step 1: Replace the entry**

In `.chezmoidata/firefox_policies.json` (lines 20–24), replace the whole `ffwebextension@merciappcom` object with:

```json
"ffwebextension@merciappcom": {
    "installation_mode": "blocked"
},
```

- [ ] **Step 2: Validate**

```bash
jaq . .chezmoidata/firefox_policies.json >/dev/null && echo "json OK"
chezmoi diff 2>&1 | grep -i merci
```
Expected: `json OK`; the diff shows the policies file changing and `run_onchange_after_install_extensions` pending (its hash covers the policy).

- [ ] **Step 3: Verify in the browser (user step, after apply and a Firefox restart)**

`about:policies` lists the extension as blocked; `about:addons` no longer lists MerciApp. If it is still listed, remove it by hand and keep the `blocked` entry.

- [ ] **Step 4: Commit**

```bash
git add .chezmoidata/firefox_policies.json
git commit -m "Block MerciApp Firefox extension"
```

---

### Task 1: Data file and chassis-filter include

**Files:**
- Create: `.chezmoidata/firefox.yaml`
- Create: `.chezmoitemplates/firefox_profiles`

**Interfaces:**
- Produces: template data `.firefox` with
  - `.firefox.profile_root` (string, `$HOME`-relative) → `.config/mozilla/firefox`
  - `.firefox.default` (string) → profile `id` marked `Default=1` and used as the link fallback
  - `.firefox.common_prefs` (list of `{key, value}`) applied to every profile
  - `.firefox.profiles` (list of `{id, name, chassis, identity, workspace, prefs}`)
- Produces: include `firefox_profiles` → JSON `{"default": "<id>", "ids": ["<id>", …]}` for the current chassis.
- Pref `value` types: `string` quoted in `user.js`; `bool`/number emitted raw.

- [ ] **Step 1: Write the data file**

```yaml
# Firefox multi-profile configuration — single source of truth.
# Consumed by: .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
#              .chezmoiscripts/run_onchange_after_configure_firefox_egl_workaround.sh.tmpl (indirectly)
#              private_dot_local/lib/scripts/desktop/executable_firefox-open.tmpl
#              private_dot_config/hypr/conf.d/firefox-profiles.lua.tmpl
# Chassis filtering happens in those consumers via .chezmoitemplates/firefox_profiles;
# data files cannot be templated.
#
# Profile identity is a classic profiles.ini (IsRelative=1 + Path=<id>).
# Requires MOZ_LEGACY_PROFILES=1 in the session environment, otherwise Firefox
# auto-creates and auto-binds a per-install dedicated profile.
# Firefox's SQLite avatar selector is disabled (browser.profiles.enabled=false).
# Addons remain global via firefox_policies.json.

firefox:
  # XDG profile root, relative to $HOME.
  profile_root: ".config/mozilla/firefox"

  # Marked Default=1 in profiles.ini (preselected by the bare `firefox` Profile Manager)
  # AND the profile `firefox-open` falls back to when no Firefox window exists.
  # Must be in the chassis set of every chassis (the include fails the render otherwise).
  default: work

  # Applied to EVERY profile's user.js. String values are quoted; bool/number raw.
  common_prefs:
    - { key: "browser.profiles.enabled", value: false }                        # disable new SQLite selector
    - { key: "toolkit.legacyUserProfileCustomizations.stylesheets", value: true } # allow theme userChrome.css
    - { key: "browser.shell.checkDefaultBrowser", value: false }
    - { key: "browser.aboutConfig.showWarning", value: false }

  # id         directory name AND window identity (firefox-<id>)
  # name       shown in profiles.ini and the chooser menu
  # chassis    which machines get this profile (.chassisType values)
  # identity   theme IDENTITY_<n> colour (1..5) for the active border
  # workspace  Hyprland workspace the window opens on (focus follows)
  # prefs      per-profile {key,value}, extends common_prefs (empty for now)
  profiles:
    - id: work
      name: Work
      chassis: [desktop, laptop]
      identity: 1
      workspace: 2
      prefs: []
    - id: leisure
      name: Leisure
      chassis: [laptop]
      identity: 2
      workspace: 3
      prefs: []
    - id: ringstone
      name: Ringstone
      chassis: [desktop, laptop]
      identity: 3
      workspace: 4
      prefs: []
```

The `identity` and `workspace` numbers are arbitrary starting values; change them freely.

- [ ] **Step 2: Write the include**

`.chezmoitemplates/firefox_profiles`:

```
{{- /* Chassis-filtered Firefox profile ids. Call: includeTemplate "firefox_profiles" . | fromJson */ -}}
{{- $ids := list -}}
{{- $hasDefault := false -}}
{{- range .firefox.profiles -}}
{{-   if has $.chassisType .chassis -}}
{{-     $ids = append $ids .id -}}
{{-     if eq .id $.firefox.default -}}{{- $hasDefault = true -}}{{- end -}}
{{-   end -}}
{{- end -}}
{{- if not $hasDefault -}}
{{-   fail (printf "firefox.default %q is not in the %s profile set" .firefox.default .chassisType) -}}
{{- end -}}
{{- dict "default" .firefox.default "ids" $ids | toJson -}}
```

It returns ids rather than profile objects on purpose: a JSON round trip turns numbers into `float64`, and Go prints `1000000.0` as `1e+06`, which would corrupt a numeric pref in `user.js`. Consumers re-read each profile from `.firefox.profiles`.

- [ ] **Step 3: Verify**

```bash
chezmoi data | jaq '.firefox.profiles | length'          # 3
echo '{{ includeTemplate "firefox_profiles" . }}' | chezmoi execute-template
```
Expected on the desktop: `{"default":"work","ids":["work","ringstone"]}`. Then simulate the laptop and a bad default without editing files:

```bash
echo '{{ $c := dict "chassisType" "laptop" "firefox" .firefox }}{{ includeTemplate "firefox_profiles" $c }}' | chezmoi execute-template
echo '{{ $f := set (deepCopy .firefox) "default" "leisure" }}{{ $c := dict "chassisType" "desktop" "firefox" $f }}{{ includeTemplate "firefox_profiles" $c }}' | chezmoi execute-template
```
Expected: `{"default":"work","ids":["work","leisure","ringstone"]}`, then a `fail` naming `leisure` and `desktop`. If `fromJson` cannot be applied to the object in a consumer, the include's output is still valid JSON; fix the consumer, not the include.

- [ ] **Step 4: Commit**

```bash
git add .chezmoidata/firefox.yaml .chezmoitemplates/firefox_profiles
git commit -m "Add firefox.yaml and the chassis-filter include for declarative profiles"
```

---

### Task 2: Session variable and the launch-behaviour gate

Without `MOZ_LEGACY_PROFILES=1` the whole approach silently fails (see Global Constraints). It must land **before** any `profiles.ini` is authored. Step 4 is a **hard gate** for Tasks 3, 6 and 7.

**Files:**
- Modify: `private_dot_config/uwsm/env.tmpl`

**Interfaces:**
- Produces: `MOZ_LEGACY_PROFILES=1` in the compositor and systemd user environment, inherited by every app launched from the session.

- [ ] **Step 1: Add the variable to `uwsm/env.tmpl`**

In the `# Browser & Electron` section, after:

```sh
# Firefox native Wayland
export MOZ_ENABLE_WAYLAND=1
```

add:

```sh
# Make the managed profiles.ini authoritative: honour Default=1 and show the classic
# Profile Manager instead of Firefox's per-install dedicated profiles, which create their
# own *.default-release + [Install<HASH>] binding and suppress both.
export MOZ_LEGACY_PROFILES=1
```

- [ ] **Step 2: Render and apply**

```bash
chezmoi execute-template < private_dot_config/uwsm/env.tmpl | grep MOZ_LEGACY_PROFILES
chezmoi diff ~/.config/uwsm/env
```
Expected: `export MOZ_LEGACY_PROFILES=1` and a diff with only the added lines. Then `chezmoi apply ~/.config/uwsm/env` (user step).

- [ ] **Step 3: Load it into the session**

uwsm reads `env` once, at session start. **Log out and back in.** Then:

```bash
systemctl --user show-environment | grep MOZ_LEGACY_PROFILES
hyprctl dispatch exec 'sh -c "echo $MOZ_LEGACY_PROFILES > /tmp/mlp.txt"'; sleep 1; cat /tmp/mlp.txt
```
Expected: `MOZ_LEGACY_PROFILES=1` and `1`. If either is empty, stop.

- [x] **Step 4: The gate — picker, identity and remoting against a throwaway home (PASSED 2026-10-14, Firefox 157.0.1)**

Appendix A was recorded on 153 under `StartWithLastProfile=1`; none of it covered `StartWithLastProfile=0`, window identity, or concurrent profiles on 157. This step proved all three on disposable data. Re-run it after a Firefox major bump or a wrapper change. Close your real Firefox first.

🚨 **Isolation takes more than `$HOME`.** The session exports `XDG_CONFIG_HOME`, and Firefox honours it before `$HOME`: the first attempt silently used the *real* profile root. Override `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_DATA_HOME`, and `env -u BASH_ENV` (the login shell's `BASH_ENV` file sources `$HOME/.config/shell/env`, which the throwaway home lacks). Symlink `$HOME/.local/lib` into the throwaway home, because the wrapper reads `PATCHED_LIB` from `$HOME` and otherwise drops to XWayland.

🚨 **`-P` matches the profile `Name=`, case-sensitively, never the directory.** `-P alpha` against `Name=Alpha` silently opens a *Profile Manager*, and `--name` still sets a class on that dialog, so a class check alone proves nothing. Always confirm the window's title is not "Choose User Profile" and the profile dir holds files.

```bash
TESTHOME=/tmp/ff-gate-home; FFROOT="$TESTHOME/.config/mozilla/firefox"
mkdir -p "$FFROOT/alpha" "$FFROOT/beta" "$TESTHOME/.local"
ln -s "$HOME/.local/lib" "$TESTHOME/.local/lib"
cat > "$FFROOT/profiles.ini" <<'EOF'
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
FF() { env -u BASH_ENV HOME="$TESTHOME" XDG_CONFIG_HOME="$TESTHOME/.config" \
    XDG_CACHE_HOME="$TESTHOME/.cache" XDG_DATA_HOME="$TESTHOME/.local/share" \
    MOZ_LEGACY_PROFILES=1 "$HOME/.local/bin/firefox" "$@"; }
```

- **A. Picker** — `FF -no-remote`: Profile Manager lists exactly Alpha and Beta, Alpha preselected; afterwards no `*.default-release`, no `[Install` line, no `installs.ini`.
- **B. Identity and remoting** (no `-no-remote`): launch `FF --name firefox-alpha --class firefox-alpha -P Alpha about:blank`, then the same for beta; `hyprctl clients -j` shows classes `firefox-alpha` / `firefox-beta` and titles that are not "Choose User Profile". Then `FF --name firefox-beta --class firefox-beta -P Beta --new-tab https://example.org`: the tab opens in beta's existing window and the parent-process count stays at 2.
- **C. Repeat B with `FIREFOX_BACKEND=x11`** (the wrapper's XWayland fallback).
- Clean up by killing only processes whose environment holds `XDG_CONFIG_HOME=$TESTHOME/.config` (`pkill -f "$TESTHOME"` misses the instances, whose command lines do not contain the path), then remove `$TESTHOME`.

**Results recorded 2026-10-14:**

| Check | Result |
|---|---|
| A: picker, `Default=1` preselect under `StartWithLastProfile=0` | ✅ Alpha preselected, only the two entries; no stray profile, `[Install]` or `installs.ini` |
| Wayland, `--name` alone | class `firefox-<id>` ✅ |
| Wayland, `--class` alone | class stays `firefox` ❌ |
| XWayland, `--name` alone | class stays `firefox` ❌ |
| XWayland, `--class` alone | class `firefox-<id>` ✅ |
| **Both flags, either backend** | class `firefox-<id>` ✅ |
| Remoting, `-P <Name> --new-tab URL` | hands off to that profile's running instance, no new process ✅ (both backends) |
| Remoting, `--profile <path> URL` | ✅ (Wayland) |
| Remoting, URL with **no profile flag** | ❌ lands in the *wrong* profile (alpha) |
| Remoting, `-P` with a name that does not match | ❌ opens a Profile Manager and a second parent process |

**Decisions taken from the results — every later task uses them:**
1. Identity is **both** flags: `--name firefox-<id> --class firefox-<id>`. Neither alone covers Wayland and XWayland, and the XWayland fallback is exactly what a fresh laptop runs before the EGL build exists.
2. Remoting routes by **profile**, not by `--name`. Every launch must name its profile: `-P "<Name>"` with the exact `Name=` from `profiles.ini` (proven on both backends). `profiles.ini` `Name=` therefore must be a single word with no quoting hazards, and the launchers and `firefox-open` pass `.name`, not `.id`.
3. `Default=1` works, so Task 4 keeps it.

- [ ] **Step 5: Commit**

```bash
git add private_dot_config/uwsm/env.tmpl
git commit -m "Set MOZ_LEGACY_PROFILES=1 so the managed Firefox profiles.ini is authoritative"
```

---

### Task 3: Adopt the existing profile (manual, once per machine)

There is no migration script: after the reinstall the situation is one real profile in the XDG root, and the steps are short enough to run by hand. This replaces the legacy-tree migration helper of earlier drafts. **On the desktop** the 198 MB profile becomes `work`; the stubs, `installs.ini` and `Profile Groups/` go. **On the laptop**, run the same steps if it has a real profile to keep, or nothing if fresh.

Close Firefox completely first; run only after Task 2 (including the logout).

- [ ] **Step 1: Reflink backup, beside the root**

```bash
cd ~/.config/mozilla
TS=$(date +%Y%m%d%H%M%S)
cp --reflink=always -a firefox firefox.backup-$TS
```
`--reflink=always` makes this fail loudly on a non-btrfs filesystem instead of silently copying. Keep the backup **outside** `firefox/`: Task 5's loop treats any dir holding `prefs.js` as a profile.

- [ ] **Step 2: Rename and clean**

```bash
cd ~/.config/mozilla/firefox
mv aybu1fna.default-release-1791981860338 work
rm -rf szhidnbj.default-release ylj1j4gt.default "Profile Groups" installs.ini profiles.ini
sed -i '/browser\.profiles\./d; /toolkit\.profiles\.storeID/d' work/prefs.js
```
The `sed` strips the selector's linkage so `work` is a plain classic profile.

- [ ] **Step 3: Verify**

```bash
ls -1 ~/.config/mozilla/firefox        # work  (+ Crash Reports, Pending Pings)
du -sh ~/.config/mozilla/firefox/work  # ~198M
grep -c 'browser.profiles' ~/.config/mozilla/firefox/work/prefs.js   # 0
btrfs filesystem du -s ~/.config/mozilla/firefox.backup-*            # 'exclusive' near 0 = a real reflink
```

- [ ] **Step 4: Nothing to commit**

The only artefact is local state. Keep the backup until you have used all profiles across several sessions, then `rm -rf ~/.config/mozilla/firefox.backup-*`.

---

### Task 4: Profile-management run_onchange script

Creates profile directories, `user.js`, `profiles.ini` and `.desktop` launchers for this chassis's profiles. Idempotent and additive: it never deletes a profile directory.

**Files:**
- Create: `.chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl`

**Interfaces:**
- Consumes: `.firefox.*` and the include (Task 1); `MOZ_LEGACY_PROFILES=1` (Task 2); the adopted `work` dir (Task 3); the identity flags decided by the Task 2 gate (`--name` **and** `--class`, plus `-P "<Name>"`).
- Produces: `~/.config/mozilla/firefox/<id>/user.js`, `~/.config/mozilla/firefox/profiles.ini`, `~/.local/share/applications/firefox-profile-<id>.desktop` — for the chassis's ids only.

- [ ] **Step 1: Write the script template**

```bash
#!/usr/bin/env bash

# Script: run_onchange_after_manage_firefox_profiles.sh
# Purpose: Declaratively manage Firefox profiles (XDG): dirs, user.js, profiles.ini, launchers
# Requirements: Arch Linux, firefox, MOZ_LEGACY_PROFILES=1 in the session environment

# Hash: {{ list .firefox .chassisType | toJson | sha256sum }}
{{- $ff := includeTemplate "firefox_profiles" . | fromJson }}

{{ includeTemplate "log_start" "Managing Firefox profiles..." }}

set -euo pipefail

if ! command -v firefox >/dev/null 2>&1; then
    {{ includeTemplate "log_skip" "Firefox not installed, skipping" }}
    exit 0
fi

PROFILE_ROOT="$HOME/{{ .firefox.profile_root }}"
APP_DIR="$HOME/.local/share/applications"

# Interlock 1: while ~/.mozilla/firefox exists Firefox ignores the XDG base entirely,
# so anything written here is dead config.
if [ -d "$HOME/.mozilla/firefox" ]; then
    {{ includeTemplate "log_warning" "Legacy ~/.mozilla/firefox present — move its profiles into the XDG root first (Task 3), then run this script by hand. Skipping." }}
    exit 0
fi

# Interlock 2: unadopted data. Writing profiles.ini now would orphan a real profile,
# and installs.ini / [Install] means Firefox ran without MOZ_LEGACY_PROFILES=1.
if [ -e "$PROFILE_ROOT/installs.ini" ] || { [ -f "$PROFILE_ROOT/profiles.ini" ] && grep -q '^\[Install' "$PROFILE_ROOT/profiles.ini"; }; then
    {{ includeTemplate "log_warning" "installs.ini / [Install] present — adopt the existing profile (Task 3) and check MOZ_LEGACY_PROFILES=1, then run this script by hand. Skipping." }}
    exit 0
fi
for dir in "$PROFILE_ROOT"/*/; do
    [ -f "${dir}prefs.js" ] || continue
    case "$(basename "$dir")" in
        {{ range $.firefox.profiles }}{{ if has .id $ff.ids }}{{ .id }}|{{ end }}{{ end }}__managed_ids_end__) ;;
        *)
            {{ includeTemplate "log_warning" "Unmanaged profile with data in the XDG root — adopt it (Task 3), then run this script by hand. Skipping." }}
            exit 0
            ;;
    esac
done

if pgrep -x firefox >/dev/null 2>&1; then
    {{ includeTemplate "log_warning" "Firefox is running — restart it for profile changes to take effect" }}
fi

{{ includeTemplate "log_step" "Ensuring XDG profile root..." }}
mkdir -p "$PROFILE_ROOT" "$APP_DIR"

# --- Per-profile directories + user.js (this chassis only) -----------------
{{ range .firefox.profiles }}{{ if has .id $ff.ids }}
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
{{ end }}{{ end }}
# --- Classic profiles.ini (no Install/StoreID) -----------------------------
# StartWithLastProfile=0 => a bare `firefox` shows the classic Profile Manager;
# Default=1 marks the preselected entry. Both only work under MOZ_LEGACY_PROFILES=1.
{{ includeTemplate "log_step" "Writing profiles.ini..." }}
cat > "$PROFILE_ROOT/profiles.ini" <<'PROFILES_EOF'
[General]
StartWithLastProfile=0
Version=2
{{ $n := 0 }}{{ range .firefox.profiles }}{{ if has .id $ff.ids }}
[Profile{{ $n }}]
Name={{ .name }}
IsRelative=1
Path={{ .id }}
{{ if eq .id $ff.default }}Default=1
{{ end }}{{ $n = add1 $n }}{{ end }}{{ end }}
PROFILES_EOF

# --- Per-profile .desktop launchers (pruned + regenerated) -----------------
# Exec names the EGL wrapper by ABSOLUTE path (see Global Constraints) and carries
# MOZ_LEGACY_PROFILES inline so a launcher works outside a uwsm session too.
# --name and --class are BOTH needed (Task 2 gate): --name sets the Wayland app_id,
# --class the XWayland WM_CLASS the wrapper falls back to. -P takes the profiles.ini
# Name= (exact, case-sensitive) so a launch hands off to that profile's running instance.
# StartupWMClass matches, so the dock and Hyprland see one app per profile.
# The prune glob is namespaced 'firefox-profile-*' so it never touches the
# firefox.desktop override that configure_firefox_egl_workaround owns.
{{ includeTemplate "log_step" "Generating per-profile launchers..." }}
rm -f "$APP_DIR"/firefox-profile-*.desktop
{{ range .firefox.profiles }}{{ if has .id $ff.ids }}
cat > "$APP_DIR/firefox-profile-{{ .id }}.desktop" <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox — {{ .name }}
Comment=Browse the Web ({{ .name }} profile)
Exec=env MOZ_LEGACY_PROFILES=1 {{ $.chezmoi.homeDir }}/.local/bin/firefox --name firefox-{{ .id }} --class firefox-{{ .id }} -P {{ .name }} %U
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=firefox-{{ .id }}
DESKTOP_EOF
{{ end }}{{ end }}
{{ includeTemplate "log_complete" "Firefox profiles managed" }}
```


- [ ] **Step 2: Render and inspect (desktop)**

```bash
chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl \
  > "$TMPDIR/ff-profiles.rendered.sh"
```
Expected: exit 0. In the output confirm: the `case` pattern line reads `work|ringstone|__managed_ids_end__) ;;`; `user.js` for `work` contains `user_pref("browser.profiles.enabled", false);` (unquoted); `profiles.ini` has `StartWithLastProfile=0`, **two** `[ProfileN]` blocks numbered 0 and 1 (no gap), `Default=1` only under `Path=work`; two launcher heredocs and no `leisure`. Check the laptop branch by hand by rendering with `chassisType` overridden, since the lint only sees the current chassis.

- [ ] **Step 3: Lint the rendered shell**

```bash
shellcheck --severity=warning "$TMPDIR/ff-profiles.rendered.sh" && bash -n "$TMPDIR/ff-profiles.rendered.sh"
```
Expected: both exit 0, no output.

- [ ] **Step 4: Run it (only after Task 3)**

`.chezmoiscripts/` entries have no target path. Run the rendered copy directly:

```bash
bash "$TMPDIR/ff-profiles.rendered.sh"
```
Expected: log lines through `🎉 Firefox profiles managed`. A `chezmoi apply` also runs it, but if an interlock fired on an earlier apply the hash is already recorded — this by-hand run is then the retry (Global Constraints).

- [ ] **Step 5: Verify on disk**

```bash
ls -1 ~/.config/mozilla/firefox/                     # work ringstone profiles.ini (+ Crash Reports …)
cat ~/.config/mozilla/firefox/profiles.ini
grep browser.profiles.enabled ~/.config/mozilla/firefox/work/user.js
grep -H '^Exec\|^StartupWMClass' ~/.local/share/applications/firefox-profile-*.desktop
```
Expected: two profile dirs each with `user.js`; `Default=1` under `work`; two launchers, each `Exec=` naming `$HOME/.local/bin/firefox` and `StartupWMClass=firefox-<id>`.

- [ ] **Step 6: Commit**

```bash
git add .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl
git commit -m "Add run_onchange script to manage Firefox profiles declaratively"
```

---

### Task 5: Retarget theme-apply-firefox to XDG + all profiles

The current script is dead and has been since the XDG root appeared: its XDG-first branch matches, it probes for `*.default-release` underneath, finds nothing it recognises, and exits 0. Rewrite it to prefer the XDG root and symlink `userChrome.css` into **every** managed profile. It loops over directories on disk, so it needs no chassis awareness.

> **⚠ Sequencing (no runtime interlock — violation is silent).** Run it before Tasks 3–4 and it matches nothing and exits 0. The silent `exit 0` is kept deliberately: `private_dot_local/lib/scripts/CLAUDE.md:114` documents that every `theme-apply-*` script skips silently when its app is absent.

**Files:**
- Modify: `private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox`

**Interfaces:**
- Consumes: `~/.config/themes/current/firefox-userChrome.css`, profile dirs from Task 4.
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

- [ ] **Step 2: Syntax-check and lint**

```bash
sh -n private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
shellcheck -s sh --severity=warning private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
```
Expected: no output from either.

- [ ] **Step 3: Apply and verify**

```bash
chezmoi apply ~/.local/lib/scripts/desktop/theme-apply-firefox
~/.local/lib/scripts/desktop/theme-apply-firefox
ls -l ~/.config/mozilla/firefox/*/chrome/userChrome.css
```
Expected: a symlink under each profile's `chrome/` pointing into `~/.config/themes/current/` (none if the theme has no `firefox-userChrome.css` — acceptable).

- [ ] **Step 4: Commit**

```bash
git add private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
git commit -m "Retarget theme-apply-firefox to XDG and all managed profiles"
```

---

### Task 6: `firefox-open` — the link and plain-launch chooser

Makes `firefox.desktop` (and therefore `xdg-open`, the Quickshell launcher and every web link) profile-aware. Uses the identity flags and `-P "<Name>"` decided by the Task 2 gate.

**Files:**
- Create: `private_dot_local/lib/scripts/desktop/executable_firefox-open.tmpl`
- Modify: `.chezmoiscripts/run_onchange_after_configure_firefox_egl_workaround.sh.tmpl`

**Interfaces:**
- Consumes: include `firefox_profiles`; `desktop/quickshell-menu` (`--json`, with its Wofi fallback); the EGL wrapper; `hyprctl`, `jaq`.
- Produces: `~/.local/lib/scripts/desktop/firefox-open [firefox args…]`.

**Argument contract.** An argument is a *target* if it looks like a URL (`scheme:…`) or names an existing file. Flags (`--new-window`, `--private-window`) are never targets and pass through unchanged.

| Targets | Behaviour |
|---|---|
| ≥1 | Profile = the profile of the most recently focused `firefox-*` window, else `default`. No menu |
| 0 (flags only, or nothing) | Menu of the chassis profiles; cancel → exit 0 |

- [ ] **Step 1: Write the template**

```sh
#!/usr/bin/env sh

# Script: firefox-open
# Purpose: Open Firefox in the right profile. A link goes to the last-focused
#          profile (else the default); a plain launch asks via the shell's menu.
# Requirements: Arch Linux, hyprctl, jaq, quickshell-menu
{{- $ff := includeTemplate "firefox_profiles" . | fromJson }}
{{- $rows := list }}
{{- range .firefox.profiles }}{{ if has .id $ff.ids }}{{ $rows = append $rows (dict "title" .name "payload" .id) }}{{ end }}{{ end }}

FIREFOX="$HOME/.local/bin/firefox"
DEFAULT="{{ $ff.default }}"
IDS="{{ join " " $ff.ids }}"
ROWS='{{ $rows | toJson }}'

# Inherit-safe: set it here too for launches from outside the uwsm session.
export MOZ_LEGACY_PROFILES=1

has_target=0
for arg in "$@"; do
    case "$arg" in
        -*) ;;
        [a-zA-Z]*:*) has_target=1 ;;
        *) [ -e "$arg" ] && has_target=1 ;;
    esac
done

valid_id() {
    for candidate in $IDS; do
        [ "$candidate" = "$1" ] && return 0
    done
    return 1
}

# -P takes the profiles.ini Name=, not the directory id
name_of() {
    case "$1" in
{{- range .firefox.profiles }}{{ if has .id $ff.ids }}
        {{ .id }}) echo "{{ .name }}" ;;
{{- end }}{{ end }}
    esac
}

if [ "$has_target" -eq 1 ]; then
    # Lowest focusHistoryID = most recently focused window
    id="$(hyprctl clients -j 2>/dev/null |
        jaq -r '[.[] | select(.class | startswith("firefox-"))] | sort_by(.focusHistoryID) | (.[0].class // "") | ltrimstr("firefox-")' \
            2>/dev/null)"
    valid_id "$id" || id="$DEFAULT"
else
    id="$(printf '%s' "$ROWS" | "$HOME/.local/lib/scripts/desktop/quickshell-menu" --json --prompt "Firefox")" || exit 0
    [ -n "$id" ] || exit 0
    valid_id "$id" || exit 1
fi

exec "$FIREFOX" --name "firefox-$id" --class "firefox-$id" -P "$(name_of "$id")" "$@"
```

`name_of` maps an id to its `profiles.ini` `Name=`: `-P` takes the name, and a miss opens a Profile Manager. The `[a-zA-Z]*:*` glob approximates the `^[a-z][a-z0-9+.-]*:` URL test; it also matches a bare `host:port`, which is acceptable.

- [ ] **Step 2: Render and lint**

```bash
chezmoi execute-template < private_dot_local/lib/scripts/desktop/executable_firefox-open.tmpl > "$TMPDIR/firefox-open.sh"
sh -n "$TMPDIR/firefox-open.sh" && shellcheck -s sh --severity=warning "$TMPDIR/firefox-open.sh"
grep -E '^(DEFAULT|IDS|ROWS)=' "$TMPDIR/firefox-open.sh"
```
Expected: clean lint; `DEFAULT="work"`, `IDS="work ringstone"`, and `ROWS` a JSON array of `{"payload":…,"title":…}` objects.

- [ ] **Step 3: Route `firefox.desktop` through it**

`run_onchange_after_configure_firefox_egl_workaround.sh.tmpl:35-37` currently rewrites **every** `Exec=` in the system entry — main `%u`, `new-window`, `new-private-window` and `open-profile-manager` — to the wrapper with one `sed`. Read the script first, keep its version-hash trigger, then after that `sed`, **for `firefox` only** (not `firefox-esr`), add a second pass that redirects every `Exec=` except `--ProfileManager`, guarded so a missing chooser cannot break the entry:

```sh
FIREFOX_OPEN="$HOME/.local/lib/scripts/desktop/firefox-open"
if [ "$entry" = firefox ] && [ -x "$FIREFOX_OPEN" ]; then
    sed -i "/--ProfileManager/!s|^Exec=${HOME}/.local/bin/firefox |Exec=${FIREFOX_OPEN} |" "$target"
fi
```
(`$entry` and `$target` stand for whatever the script's loop variables are named — match them.) The classic Profile Manager action stays on the wrapper. `xdg-mime` already points at `firefox.desktop`, so no mime change is needed.

- [ ] **Step 4: Apply and verify**

```bash
chezmoi apply ~/.local/lib/scripts/desktop/firefox-open
grep -n '^Exec' ~/.local/share/applications/firefox.desktop
```
Expected after the EGL script runs: three `Exec=` lines naming `firefox-open`, one (`--ProfileManager`) naming `.local/bin/firefox`. Dry-run the logic without launching: `sh -x ~/.local/lib/scripts/desktop/firefox-open https://example.org` with Firefox closed should `exec` the wrapper with `--name firefox-work --class firefox-work -P Work`.

- [ ] **Step 5: Commit**

```bash
git add private_dot_local/lib/scripts/desktop/executable_firefox-open.tmpl \
        .chezmoiscripts/run_onchange_after_configure_firefox_egl_workaround.sh.tmpl
git commit -m "Add firefox-open chooser and route firefox.desktop through it"
```

---

### Task 7: Hyprland identity — workspace and border per profile

Gives each profile's windows its own workspace (focus follows) and an active-border colour taken from a theme `IDENTITY_<n>` slot, so the context is visible at a glance.

**Files:**
- Create: `private_dot_config/hypr/conf.d/firefox-profiles.lua.tmpl`
- Audit: Quickshell/Hyprland consumers keyed on `class == "firefox"`.

**Interfaces:**
- Consumes: `.firefox.profiles` + the include; `~/.config/themes/current/colors.sh`; `o.window` (`hypr/conf/helpers.lua`).
- Produces: window rules matching `^firefox-<id>$`.

`conf.d` is loaded by `require_all.files` with bare names (`hyprland.lua.tmpl:58-60`). The Lua config is live, so there is no `.conf` twin.

- [ ] **Step 1: Write the template** (tabs, stylua defaults)

```lua
-- Per-profile Firefox windows: workspace + identity border.
-- Generated from .chezmoidata/firefox.yaml. Colours are read from the current theme's
-- colors.sh at config load; theme-switcher runs `hyprctl reload`, so they follow switches.
{{- $ff := includeTemplate "firefox_profiles" . | fromJson }}

local function identity(n)
	local f = io.open(os.getenv("HOME") .. "/.config/themes/current/colors.sh", "r")
	if not f then
		return nil
	end
	local text = f:read("*a")
	f:close()
	local hex = text:match("IDENTITY_" .. n .. '="#(%x%x%x%x%x%x)"')
	return hex and ("rgba(" .. hex .. "ff)") or nil
end

{{ range .firefox.profiles }}{{ if has .id $ff.ids }}
do
	local rule = { workspace = "{{ .workspace }}" }
	local color = identity({{ .identity }})
	if color then
		rule.border_color = color
	end
	o.window("^firefox-{{ .id }}$", rule)
end
{{ end }}{{ end }}
```

The class match is **regex (RE2)**, not a Lua pattern: a hyphen needs no escape, and `%-` would match nothing. Colours are 8 hex digits (`rrggbbaa`) — a 10-digit value silently truncates (`.claude/rules/hyprland-lua.md`). The rule is deliberately not `silent`, so focus follows the window to its workspace.

- [ ] **Step 2: Render and lint**

```bash
chezmoi execute-template < private_dot_config/hypr/conf.d/firefox-profiles.lua.tmpl | luajit -bl - >/dev/null
mise run lint:lua
```
Expected: no output. The lint sees only the current chassis; check the laptop branch by rendering with `chassisType` overridden.

- [ ] **Step 3: Prove the two untyped parts in a nested Hyprland**

`--verify-config` cannot prove rule *effects* (the stubs leave them untyped). Use the nested-instance method from `hyprland-lua.md`, then:

- the effect field really is `border_color`, and the colour changes on a window whose class matches (`hyprctl clients -j`, a screenshot, or `hyprctl getoption`);
- the workspace string's meaning under **hyprsplit** (is `"2"` global or monitor-local, and does it land on the focused monitor?). Read the reply text, not just the exit code: `info:` can mean "succeeded without doing anything".

If a field name differs, fix it in this template and re-run.

- [ ] **Step 4: Audit consumers of the old class**

```bash
grep -rn 'firefox' private_dot_config/quickshell private_dot_config/hypr private_dot_local/lib/scripts
```
Anything keyed on `class == "firefox"` or `appId === "firefox"` (Quickshell app-icon or glyph maps, window rules) stops matching once windows are `firefox-<id>`. Make each a prefix match. The Picture-in-Picture rule is title-based (`windowrules.lua:27`) and unaffected.

- [ ] **Step 5: Apply and commit**

```bash
chezmoi apply ~/.config/hypr/conf.d/firefox-profiles.lua && hyprctl reload
git add private_dot_config/hypr/conf.d/firefox-profiles.lua.tmpl
git commit -m "Add per-profile Firefox workspace and identity-border Hyprland rules"
```

---

### Task 8: End-to-end verification (human gate)

No new files. Steps need an interactive GUI session and cannot be completed by an agent.

- [ ] **Step 1: Automated sweep**

```bash
chezmoi execute-template < .chezmoiscripts/run_onchange_after_manage_firefox_profiles.sh.tmpl | shellcheck --severity=warning -
chezmoi execute-template < private_dot_local/lib/scripts/desktop/executable_firefox-open.tmpl | shellcheck -s sh --severity=warning -
sh -n private_dot_local/lib/scripts/desktop/executable_theme-apply-firefox
mise run lint:lua
chezmoi data | jaq '.firefox.profiles | length'   # 3
```
Expected: clean everywhere, `3`.

- [ ] **Step 2: Profiles and picker (Firefox closed)**

Run `firefox -P` in a terminal. Expected on the desktop: exactly `Work` and `Ringstone`. Run bare `firefox`: the classic Profile Manager with `Work` preselected (or arbitrary, if the Task 2 gate said `Default=1` is inert). Choose `Work`; `about:profiles` shows it rooted at `~/.config/mozilla/firefox/work` with your existing history. Then, Firefox closed:

```bash
ls -1 ~/.config/mozilla/firefox/                       # work ringstone (+ Crash Reports, Pending Pings, profiles.ini)
grep -c '^\[Install' ~/.config/mozilla/firefox/profiles.ini   # 0
grep StartWithLastProfile ~/.config/mozilla/firefox/profiles.ini   # =0
test ! -e ~/.config/mozilla/firefox/installs.ini && echo "no installs.ini"
```
No stray `*.default-release`, no `[Install…]`, no `installs.ini`, and `StartWithLastProfile` still `0` (Firefox rewrites `profiles.ini` on exit).

- [ ] **Step 3: The chooser**

- `gtk-launch firefox` (Firefox closed): the Quickshell menu lists `Work` and `Ringstone`; choosing one opens that profile; Esc opens nothing.
- With Firefox closed, `xdg-open https://example.org`: opens `Work` (the default), no menu.
- Open `Ringstone`, focus it last, then `xdg-open https://example.org`: lands in **Ringstone**. Focus `Work` last: lands in Work.
- The "New Private Window" action from the launcher behaves like a plain launch (menu), and "Profile Manager" still opens the classic dialog.

- [ ] **Step 4: Identity and launchers**

- `gtk-launch firefox-profile-ringstone`: opens Ringstone directly, no menu; the window maps (an unwrapped launch shows processes and no window).
- Each profile's window opens on its configured workspace (focus follows) with its identity border; `hyprctl clients -j` shows class `firefox-<id>`.
- Run `theme-switcher` to another theme: the borders recolour.
- No profile avatar button in the toolbar; `about:config` shows `browser.profiles.enabled` = `false`.

- [ ] **Step 5: Record**

```bash
git commit --allow-empty -m "Verify declarative Firefox profiles end-to-end"
```

> **Backup retention.** `~/.config/mozilla/firefox.backup-<ts>` is a reflink clone costing almost nothing. Keep it until all profiles have been used across several sessions; then `rm -rf ~/.config/mozilla/firefox.backup-*`. Space is reclaimed only for blocks the live profile has since rewritten.

---

### Task 9: Document the data file and the include

**Files:**
- Modify: `.claude/rules/chezmoi-data.md`
- Modify: `.claude/rules/chezmoi-templates.md`
- Modify: `private_dot_local/lib/scripts/CLAUDE.md` (only if it lists the `desktop/` scripts)

- [ ] **Step 1: `chezmoi-data.md`**

Add to the Data Files Overview table, after the `ai.yaml` row:

```markdown
| `firefox.yaml` | Firefox profiles: per-profile chassis/identity/workspace, default, prefs | `{{ .firefox.* }}` |
```

Add to the Hash-Triggered Scripts table:

```markdown
| `firefox.yaml` | `run_onchange_after_manage_firefox_profiles.sh.tmpl` | AFTER file application |
```

Under "Data files", add a line for `.firefox.profiles[].{id,name,chassis,identity,workspace,prefs}` and note that chassis filtering lives in the `firefox_profiles` include, not the data.

- [ ] **Step 2: `chezmoi-templates.md`**

Add a row to the Utility Templates table:

```markdown
| `firefox_profiles` | manage-profiles script, `firefox-open`, `hypr/conf.d/firefox-profiles.lua.tmpl` | Chassis-filtered Firefox profile ids + `default` as JSON; fails the render if `default` is outside the chassis set |
```

- [ ] **Step 3: `private_dot_local/lib/scripts/CLAUDE.md`**

If it has a desktop-script list, add `firefox-open` (link → last-focused profile, plain launch → menu).

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/chezmoi-data.md .claude/rules/chezmoi-templates.md private_dot_local/lib/scripts/CLAUDE.md
git commit -m "Document firefox.yaml, the firefox_profiles include and firefox-open"
```

---

## Appendix A: Verified Firefox behaviour

Recorded because several rows contradict the obvious reading of the docs, and the plan depends on them.

> **⚠ Version gap.** The first six rows were recorded on Firefox **153.0.1**; the installed Firefox on 2026-10-14 is **157.0.1**. The last three rows were observed on 157. The Task 2 gate re-proved picker, preselection, identity and remoting on 157 (see its results table).
>
> **Coverage.** Every 153 row was recorded under `StartWithLastProfile=1`. The plan ships `StartWithLastProfile=0`; the Task 2 gate verified on 157 that the picker appears, `Default=1` preselects, and window identity and per-profile remoting work (both backends).

| Claim | Result |
|---|---|
| XDG profile root | Profile dirs **and** `profiles.ini` both under `$XDG_CONFIG_HOME/mozilla/firefox`. `XDG_DATA_HOME` is not used for profiles. |
| Legacy trigger | `~/.mozilla/firefox`, **not** `~/.mozilla`. An empty `~/.mozilla` still yields XDG. |
| `Default=1` alone | **Ignored.** Firefox created its own `vrte1071.default-release`, added `[Install4F96D1932A9F858E]` + `installs.ini`, left the managed profiles untouched. |
| `Default=1` + `MOZ_LEGACY_PROFILES=1` | **Honoured.** Managed profile used, no stray profile, `profiles.ini` left byte-identical. |
| `[Install<HASH>]` written by hand | Also works, but `HASH` is derived from the installation directory — machine/path specific, and unavailable on a fresh install. Rejected in favour of the env var. |
| Profile-group SQLite | `Profiles` table is 7 columns (`id, path, name, avatar, themeId, themeFg, themeBg`). Display names live **only** here, which is what the retired migration script read. Not needed any more: the reinstall left no named profiles. |
| 157.0.1, in situ (2026-10-14) | Without `MOZ_LEGACY_PROFILES=1` this machine got `aybu1fna.default-release-…` bound by `[Install4F96D1932A9F858E] Locked=1` and `installs.ini`, plus two stub profiles and two empty `Profile Groups/*.sqlite`. The dedicated-profile takeover still happens on 157. |

## Appendix B: The "Hybrid" Alternative (not implemented)

This plan implements **classic declarative** — the robust path that gives up Firefox's in-app avatar/theme profile switcher in exchange for zero coupling to a browser-owned, version-unstable SQLite schema. If the avatar switcher turns out to be a must-have, the **hybrid (reconcile)** approach is the fallback. It is documented so the decision — and its cost — stays visible.

**What it adds over this plan:**

- **Keep** `browser.profiles.enabled=true` (drop that line from `common_prefs`) and drop `MOZ_LEGACY_PROFILES=1` (Task 2).
- **Do not** write `profiles.ini` by hand. Let Firefox bootstrap a profile *group* once (its `StoreID`, group UUIDs, schema migrations and `Profile Groups/<StoreID>.sqlite` all created by Firefox — never authored by us).
- Add a **reconcile step** (Firefox closed, WAL checkpointed) that opens the existing `Profile Groups/<StoreID>.sqlite` and `INSERT`/`UPDATE`s **only** the 7-column `Profiles` table so its rows match `firefox.yaml`, pointing `path` at the same dirs this plan creates. `avatar`/`themeId`/`themeFg`/`themeBg` become new per-profile fields.

**Why it is the fallback, not the default:**

- The `SelectableProfileService` schema is new (~FF 140), undocumented and evolving — an update can silently break the reconcile step.
- Identity is spread across `profiles.ini` (`StoreID`), `installs.ini`, the SQLite filename and per-profile prefs (`toolkit.profiles.storeID`, `browser.profiles.*`, group UUIDs in `SharedPrefs`). We would only safely own the `Profiles` table.
- It requires Firefox fully closed on every apply (WAL lock).

If this fallback is ever chosen, it is a separate spec/plan cycle: it changes Task 1 (avatar/theme fields), removes Task 2's variable, replaces Task 4's `profiles.ini` generation with a reconcile script, and changes how Task 3 adopts data. Note `firefox-open` and Task 7 depend only on the `firefox-<id>` window identity, not on how profiles are registered, so they survive that change.

**Residual risk of the chosen path:** `MOZ_LEGACY_PROFILES` is an escape hatch for Mozilla's dedicated-profiles rollout and could be removed in a future release. The symptom is exactly what Task 8 Step 2 checks for — a stray `*.default-release` and an `[Install…]` section — and the fix is to fall back to emitting the `[Install<HASH>]` section from the hash already present in `profiles.ini`.

---

## Self-Review

**Spec coverage** (against the 2026-10-14 decisions):
- Profiles `work`/`leisure`/`ringstone`, chassis-gated (desktop: work+ringstone; laptop: all) → Task 1 data + include, consumed in Tasks 4, 6, 7. ✅
- Existing 198 MB profile becomes `work`; stubs, `installs.ini`, `Profile Groups/` removed; no script → Task 3 (manual). ✅
- Links go to the last-focused profile, else `default`, never prompt; plain launch shows the Quickshell menu; bare `firefox` keeps the classic picker → Task 6 + `StartWithLastProfile=0` in Task 4. ✅
- Per-profile window identity → `--name`/`--class` in Tasks 4 and 6, proven in the Task 2 gate (incl. XWayland fallback). ✅
- Per-profile workspace (follow focus) and theme-identity border → Task 7. ✅
- MerciApp removed → Task 0 (`blocked`, not deleted). ✅
- Ringstone as another work context → `prefs: []`. ✅
- XDG target, classic `profiles.ini`, SQLite selector disabled, global addons, EGL wrapper on every path → Global Constraints. ✅
- Hybrid alternative → Appendix B. ✅

**Open items carried into execution** (each has a cheap test and a recorded fallback):
1. Whether `Default=1` preselects under `StartWithLastProfile=0` (Task 2 Step 4 A).
2. ~~Whether `--name`/`--class` separate window identity and remoting on both backends~~ **Resolved 2026-10-14**: both flags together, plus `-P "<Name>"` (Task 2 gate).
3. The Hyprland rule field names and the workspace semantics under hyprsplit (Task 7 Step 3).
4. Whether `blocked` uninstalls an already-installed extension (Task 0 Step 3).

**Placeholder scan:** no `TBD`/`TODO`. `$entry`/`$target` in Task 6 Step 3 are named after variables the existing script defines, which that step tells the implementer to read first.

**Type/name consistency:** `.firefox.profile_root`, `.default`, `.common_prefs[].{key,value}`, `.profiles[].{id,name,chassis,identity,workspace,prefs}` are used identically in Tasks 1, 4, 6, 7; the include returns `{default, ids}` and every consumer reads `$ff.ids` / `$ff.default` and re-reads profile objects from `.firefox.profiles`; ids `work`/`leisure`/`ringstone` and the `firefox-<id>` identity are consistent across data, launchers, chooser, Hyprland rules and the theme loop.

**Ordering consistency:** 3 → 4 → 5 is strictly sequential and enforced at runtime by Task 4's two interlocks (with the by-hand retry caveat); 6 and 7 follow the Task 2 gate; 0 and 1 are independent. ✅
