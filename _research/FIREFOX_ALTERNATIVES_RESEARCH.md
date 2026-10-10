# Firefox-Based Browser Alternatives: Research

Evaluates Gecko/Firefox-derived browsers as a replacement for stock Firefox, **before** committing
to `_plans/FIREFOX_PROFILES_IMPLEMENTATION_PLAN.md` (committed on branch
`firefox-profiles`, not yet executed). Chromium-based browsers are out of scope by requirement.

**Date**: 2026-08-08 · **System Firefox**: 153.0.3-2 (`extra`)

**Verdict up front**: only **LibreWolf** is a defensible switch today, and the case for it is a
supply-chain and policy-dedup case, not a features case. **Glide** is the one worth wanting — it is
the only entry that would genuinely improve *how we configure a browser* — but it ships alpha builds
off the Firefox **beta** channel with no out-of-band security path, so it is a "not yet". Nothing
here makes multi-profile easier; that machinery is Gecko's, and every fork inherits it unchanged.

---

## 1. What we are actually protecting

The existing Firefox integration, measured:

| Surface | Artefact | Size |
|---|---|---|
| Package | `.chezmoidata/packages.yaml` → `firefox` | 1 line, `extra` |
| Default app | `.chezmoidata/globals.yaml` → `applications.browser` | 1 line, drives `$BROWSER` + mimeapps |
| Enterprise policy | `.chezmoidata/firefox_policies.json` + `run_onchange_after_install_extensions.sh.tmpl` | 23 KB, 19 policy keys, 6 extensions, 4 search engines |
| Theming | `themes/*/firefox-userChrome.css` + `desktop/executable_theme-apply-firefox` | **8 files × 343 lines = 2744 lines**, 27 chrome selectors |
| Session | `dotfiles/session-browsers.conf` | class `firefox` |
| Hyprland | `bindings/applications.conf.tmpl` + `.lua`, `windowrules.conf` | `SUPER+W` → `firefox` |
| **Pending** | `_plans/FIREFOX_PROFILES_IMPLEMENTATION_PLAN.md` | 866 lines, 7 tasks, not yet executed |

The 2744 lines of `userChrome.css` are the migration cost centre. They target Firefox chrome IDs
(`#TabsToolbar`, `#back-button`, `.tabbrowser-tab[selected]` …). Their portability is the single
biggest cost differentiator between candidates, and it splits the field cleanly:

- **Same chrome as Firefox** (LibreWolf, Waterfox) → CSS ports ~1:1.
- **Rewritten chrome** (Zen, Floorp) → the 27 selectors are largely meaningless; 8 themes need
  rewriting against a different, less stable, less documented widget tree.

---

## 2. The decisive external fact: the AUR is under active attack

This is not background colour — it determines the answer.

- **2026-07-30**: Arch disabled AUR **package adoption** after a malware wave; pushes were later
  disabled entirely during incident handling.
- **29 Jul – 2 Aug 2026**: ≥89 corroborated packages, anchored by `openconnect-sso`. Tor-backed
  two-stage RAT, credential theft, SSH lateral movement, persistence. **Third wave since June 2026.**
- Attack vector: adopting orphaned packages, then inserting binaries and privileged steps into the
  *build* process — not merely dependency edits.
- **No browser packages appear in the published batches.** The exposure is structural, not a
  known compromise of any candidate here.

Consequences visible in the data:

```
zen-browser-bin  1.21.10b   flagged out-of-date 2026-08-06   (upstream is 1.21.12b)
librewolf-bin    153.0.1_1  flagged out-of-date 2026-08-06   (upstream is 153.0.3)
zen-browser      1.21.6b    flagged out-of-date 2026-08-07
```

AUR-sourced browsers are currently **shipping stale Gecko while Gecko CVEs are being fixed
upstream**. That is the opposite of what a browser needs.

Against `private_dot_local/lib/scripts/system/CLAUDE.md` → Package Security Policy: every
candidate except LibreWolf is *true AUR* tier — tripwire-gated, requiring `package-manager approve`
on every PKGBUILD change.

> **Wider finding, out of scope but worth its own look**: chaotic-aur rebuilds AUR PKGBUILDs. Its
> signature attests to *who built it*, not *what the build script did*. The policy currently treats
> chaotic-aur as an official tier. During an active AUR build-script campaign that assumption
> deserves re-examination — `librewolf` resolves to chaotic-aur on this machine today.

---

## 3. Candidates

The field was swept against the full `firefox-based` tag listing on AlternativeTo (25 entries,
checked 2026-08-08). Five entries warrant evaluation (§3.1–§3.5); the rest are triaged below.

**Reference points** (Mozilla `firefox_versions.json`, 2026-08-08): release **153.0.3**, ESR
**140.13.0esr**, ESR-next **153.0esr**, beta **154.0b8**.

#### Fit-disqualified — anti-fingerprinting browsers

| Browser | Why not |
|---|---|
| **Mullvad Browser** | Refused on **fit, not quality** — operationally it is the best-run project in this document (see note below). But: *private browsing on by default*, so logins and cookies do not survive a restart — a "work profile" that forgets your sessions is not a work profile. Letterboxing pads every window with grey bars, which under a tiling WM means it fires constantly; the maximise warning [cannot be dismissed](https://github.com/mullvad/mullvad-browser/issues/44) and `privacy.resistFingerprinting.letterboxing=false` [does not turn it off](https://github.com/mullvad/mullvad-browser/issues/355). Upstream also advises against installing extensions, and we install six. |
| **Tor Browser** | Same posture, more so, plus routing we do not want by default. |

> **Note on Mullvad, because it is the one near-miss.** `mullvad-browser-bin` is AUR popularity
> **6.0** (the highest of any candidate here), not flagged out-of-date, cadence ~monthly
> (15.0.14 May → 15.0.16 Jun → 15.0.18 14 Jul → 15.0.19 24 Jul). Release 15.0.19 is *"Updated
> Firefox to 140.13.0esr"* + *"Bug 45124: Backport Security Fixes from Firefox 153"* — an explicit
> out-of-band security path, exactly the thing Glide lacks (§3.5). It installs to
> `/opt/mullvad-browser/`, creates profiles in `$HOME`, and the packager writes only a
> `distribution.ini`, so our `policies.json` drop would be additive as it is on Firefox today.
> If the requirement were ever "hardest privacy, one profile, no persistence", this is the answer.

#### Engine-disqualified — not modern Gecko

| Browser | Why not |
|---|---|
| **Pale Moon / Basilisk** | Goanna, not modern Gecko. No WebExtensions parity — `uBlock0`, Karakeep, LeechBlock all break. `palemoon-bin` flagged out-of-date since 2026-06-18. |
| **K-Meleon** | Windows-only, ancient Gecko. |

#### Dead or never shipped

| Browser | Evidence |
|---|---|
| **Pulse Browser** | GitHub repo **archived**; last push 2024-05-16. |
| **Dot Browser** | **Zero releases ever**; last push 2024-12-25. |

#### Out of scope

| Browser | Why |
|---|---|
| **IronFox, Fennec F-Droid, Iceraven, Firefox Focus** | Android/iOS only. |
| **r3dfox, Mypal, R&S Browser in the Box** | Windows-only legacy/VM targets. |
| **Camoufox** | A scraping and anti-bot-evasion build, not a daily driver. |
| **Firefox Developer Edition** | *Is* Firefox, on the beta channel — the same channel that disqualifies Glide (§3.5), without Glide's compensating config surface. |
| **Firefox Unbranded** | Mozilla's own build that permits unsigned add-ons. We install extensions via `ExtensionSettings` policy from AMO; unsigned installs are not a need we have. |
| **Firefox Profilemaker** | A web tool that emits a `user.js`, not a browser. Overlaps Betterfox/arkenfox; relevant to the profiles plan at most as a `user.js` source, and we already template that ourselves. |

#### Evaluated and rejected on merits

| Browser | Why not |
|---|---|
| **GNU IceCat** | **Not stale** — `icecat` is at **140.13.0**, which is precisely the current ESR, 253 votes, PKGBUILD touched 2026-07-21, not flagged. The problem is that it buys us nothing: LibreJS blocks nonfree JavaScript site-wide (breaks most of the web on a work profile), it substitutes its own add-on sources, and every privacy default it sets LibreWolf also sets — on the **release** channel rather than ESR. Strictly dominated by §3.1. |
| **FireDragon** | Garuda Linux's browser. Per its own README it is *"based on Firefox with privacy-focused patches and settings from LibreWolf"* — so it is LibreWolf plus Garuda opinions: uBlock Origin and Flagfox preinstalled, **Firefox Sync defaulted to a Garuda-operated sync server**, and the Lepton UI skin, which would fight all 27 of our `userChrome.css` selectors. Release cadence 13.0.0 (26 Jul) → 13.1.1 (5 Aug) — four releases in ten days, and the AUR package is already two behind at 13.0.1. 7 stars upstream, `firedragon-bin` 5 votes. All of LibreWolf's cost, none of its neutrality. |

### 3.1 LibreWolf — the only switchable candidate today

| | |
|---|---|
| Version | **153.0.3_1-1**, matching system Firefox 153.0.3 exactly |
| Repo | **`extra`** — official, signed, `SigLevel = Required` satisfied |
| Packager | `kpcyrd` (Arch security / reproducible-builds developer) |
| Built | **2026-08-07T12:45Z** |
| Base | Firefox rapid release, tracks upstream release-for-release |
| Chrome | Unmodified Firefox chrome |

**Landed in `extra` yesterday.** Read the provenance honestly before relying on it:

- It was packaged in response to the AUR being frozen, which had left AUR `librewolf` stale
  (`aur-general` thread, 2026-08-07).
- LibreWolf upstream was apparently **not consulted** — this is an Arch-side decision
  (codeberg `librewolf/issues#3159`, opened 2026-08-07, upstream reacting with "LOL").
- **PGO was removed** from the `extra` PKGBUILD relative to the AUR one. Expect some performance
  regression vs. a PGO build; unquantified.
- Repo is `gitlab.archlinux.org/archlinux/packaging/packages/librewolf`.

So: strictly better *supply chain* than any AUR fork, but a **one-day-old** packaging channel with
a known build-flag regression. That is a real caveat, not a footnote.

**What it brings over Firefox**: telemetry/Pocket/Studies stripped at build time; RFP on by default;
HTTPS-only; strict ETP; DoH off; Safe Browsing off; password manager off; AI features blocked by
policy. Plus `librewolf.overrides.cfg` — a **JS config file applied across all profiles**, the only
configuration-management gain available on a release-channel Gecko. (Glide's `glide.ts` is
strictly better as a config surface — see §3.5 — but is not on a release channel.)

**What it costs**:

1. **`policies.json` collision — the sharp edge.** Arch's `firefox` ships
   `distribution/distribution.ini` but *no* `policies.json`, so our script's `sudo tee` is purely
   additive. LibreWolf **ships its own 18 KB `policies.json`** at
   `/usr/lib/librewolf/distribution/policies.json`. The current script would clobber it, silently
   losing `DisableAppUpdate` (**pacman manages updates — without this LibreWolf starts self-update
   checking**), the `AIControls` blocks, `allowed_types` extension restrictions, and their search
   hardening. Migration requires **merging**, not replacing.
2. Offsetting that: **~60% of our 19 policy keys become redundant** — `DisableTelemetry`,
   `DisableFirefoxStudies`, `DisableFeedbackCommands`, `NoDefaultBookmarks`,
   `DontCheckDefaultBrowser`, DuckDuckGo default, Amazon/eBay removal and `uBlock0` auto-install are
   all already in LibreWolf's shipped policy. Genuine net simplification *if merged deliberately*.
3. **RFP breaks the theme system.** Resist-fingerprinting forces a light theme and fixed window
   sizes. `themes/*/firefox-userChrome.css` includes four dark themes; the darkman solar
   auto-switch would visibly disagree with the browser. Needs `privacy.resistFingerprinting=false`
   in `librewolf.overrides.cfg` — trading away LibreWolf's headline feature to keep ours.
4. **DRM off by default** (`EncryptedMediaExtensions.Enabled: false`) — Widevine sites break until
   re-enabled.
5. **XDG path is unsettled.** Docs place the override at
   `$XDG_CONFIG_HOME/librewolf/librewolf/librewolf.overrides.cfg`, implying a profile root of
   `~/.config/librewolf/librewolf/` — *not* the `~/.config/mozilla/firefox/` shape the plan assumes.
   The FAQ states there is **"no officially supported migration path currently, since there are
   still open issues."** ⚠ **Unverified and load-bearing** — see §6.

### 3.2 Zen — the tempting one, and the one to refuse

| | |
|---|---|
| Version | 1.21.12b (2026-08-07), AUR stuck at **1.21.10b**, flagged |
| Repo | **AUR only** — prebuilt tarball from GitHub Releases into `/opt` |
| Upstream | 43.8k stars, MPL-2.0, very much alive |
| Base | Firefox 153.0.3, absorbs Mozilla security patches within ~0–4 days |

Upstream health and patch cadence are genuinely good — better than the fork stereotype. The
problems are all ours, not theirs:

- **Cadence × tripwire.** Five releases in 21 days (1.21.8b → 1.21.12b). Each bumps `pkgver` and
  `sha256sums`, changing the PKGBUILD hash, so each requires a manual `package-manager approve`.
  ~2 interactive supply-chain approvals per week, forever, during an active AUR campaign.
- **Prebuilt binary tarball**, not built from source by a signed repo. Weakest provenance in the
  comparison.
- **Its own `policies.json`** at `/opt/zen-browser-bin/distribution/policies.json` (the PKGBUILD
  installs one to disable update checks) — same collision as LibreWolf, in a path that changes if
  you switch between `zen-browser` and `zen-browser-bin`.
- **All releases carry a `b` suffix.** Every "stable" release is labelled beta.
- **2744 lines of userChrome.css become scrap.** Zen's chrome is heavily rewritten; theming goes
  through Zen Mods / `zen-themes.json`, an ecosystem-specific mechanism, not our semantic-variable
  pipeline.
- **Workspaces are not profiles.** They partition tabs within one profile — one cookie jar, one
  set of logins, one extension state. That does not deliver work/leisure separation. Profile-per-
  space is an *open discussion* (`zen-browser/desktop#11646`), not a feature.

Zen's XDG story is actually ahead of Firefox's (`~/.config/zen`, with `~/.zen` fallback) — noted
for completeness, but it does not offset the above.

### 3.3 Floorp

Firefox rapid-release base since 12.1.0. AUR-only (`floorp-bin`, 68 votes, xiota) — same tripwire
tax, one fewer release per week. Rewritten chrome, so the same 2744-line write-off as Zen.

Its one distinctive idea is worth recording: **Workspaces with per-workspace Multi-Account
Container assignment**. That is the closest anything here comes to the goal — containers give real
cookie/storage isolation, and pinning them to a workspace makes the separation ambient rather than
per-tab. But containers still share extensions, history, and passwords, so it is weaker isolation
than profiles, and it costs an AUR dependency plus a theme rewrite to get it.

### 3.4 Waterfox

**ESR-based** — 6.6.x is Gecko **ESR 140** while Firefox is at 153. Security-supported (6.6.16
shipped ESR 140.13 fixes ahead of Mozilla's 2026-07-21 release, which is a good sign about the
maintainer) but a full year behind on the engine. 6.7 moves to ESR 153.

Chrome is close to Firefox's, so the CSS would largely port — the one non-LibreWolf candidate where
that is true. But: AUR-only, single-maintainer, non-SPDX licence (`NOASSERTION`), and
**deliberately installs Chrome Web Store extensions** — an *additional* extension supply-chain
surface, which is the wrong direction for this repo. ESR also means the profiles work would be
built against an engine we then have to re-verify at the 6.7/ESR 153 jump.

### 3.5 Glide — best configuration story in the field, worst release channel

`glide-browser.app` · `glide-browser/glide` · MPL-2.0 · **the closest thing here to a fork built
for a repo like this one**, and the one whose flaw is hardest to work around.

| | |
|---|---|
| Released | **0.1.63a**, 2026-06-28 (**alpha**, per its own docs and the `a` suffix) |
| Gecko base | **Firefox 153.0b5 — the *beta* channel**, not release |
| `main` HEAD | 153.0b13 (commit 2026-07-19); **no release cut since 0.1.63a** |
| Repo | AUR `glide-browser-bin`, **3 votes**, popularity **0.04** |
| Maintainership | RobertCraigie **1361** commits; next contributor **16** |
| Created | 2025-04-05 |

**Why it is genuinely interesting here** — it answers the *"how much easier to configure"* half of
the question better than anything else researched, LibreWolf included:

1. **`~/.config/glide/glide.ts` — one XDG-native TypeScript file.** Type-stripped via
   `ts-blank-space`, LSP-supported, `:config_reload` without restart. This is the *only* candidate
   whose primary configuration surface is a plain text file in `$XDG_CONFIG_HOME` — i.e. a normal
   chezmoi-managed template. Compare what we do today: 23 KB of JSON shoved into a root-owned
   `distribution/` directory by a `sudo tee` in a `run_onchange` script.
2. **Config resolution order is cwd → *profile directory* → `$XDG_CONFIG_HOME/glide/`.** Per-profile
   config is a first-class feature, which composes directly with the work/leisure split the plan is
   trying to build — different keymaps and site rules per profile, no extra machinery.
3. **`userChrome.css` and `userContent.css` are enabled by default.** The
   `toolkit.legacyUserProfileCustomizations.stylesheets` prerequisite documented in
   `theme-apply-firefox` and in all 8 theme CSS headers simply goes away.
4. **"Purely additional" to Firefox** by its own description, so the 27 chrome selectors should
   survive — same class as LibreWolf, unlike Zen/Floorp. *Unverified; needs the Browser Toolbox probe.*
5. **Betterfox included by default**, AI features off, newtab shortcuts off — overlaps a chunk of
   our 19 policy keys, like LibreWolf but without the collision: **the AUR PKGBUILD ships no
   `distribution/policies.json`**, so our script stays purely additive at
   `/opt/glide-browser-bin/distribution/policies.json`.
6. **Auto-updater disabled on Linux** — already pacman-correct, no `DisableAppUpdate` needed.
7. Classic profile machinery intact — the packaged `.desktop` ships an `--ProfileManager` action.
8. Modal vi keybindings, hint mode, fuzzy tab switching, site-specific keymaps, `glide.process`
   for spawning commands. Fits a Neovim/Hyprland/keyboard-first system better than any other entry.

**Why it still fails, and it is not close**:

1. **It tracks the Firefox *beta* channel, by design and by documented choice** — *"purely for
   decreased maintenance burden… In the future, Glide may be based off of Firefox release instead."*
   That is an explicit trade of release-channel stability for maintainer convenience. Defensible for
   the project; not something to put in front of a work profile's session cookies.
2. **Gecko bumps ship only inside feature releases.** The changelog pattern is one line per release
   — "Bumped Firefox from 152.0b2 to 153.0b5". There is **no out-of-band security-release path**.
   Concretely: the binary you would install today is on a Gecko snapshot from **on or before
   2026-06-28**, and has received neither Firefox 153.0 final nor 153.0.1 / .2 / .3. The bump to
   153.0b13 has been sitting on `main` **unreleased since 2026-07-19**. Contrast Zen, which absorbed
   Mozilla's July patch in ~4 days.
3. **Alpha, and says so.** Version `0.1.63a`; docs open with *"Glide is in alpha. There will be
   missing features and bugs."*
4. **Bus factor 1.** 98% of commits are one person. Monthly-ish releases, last one 6 weeks ago.
5. **AUR-only with 3 votes and 0.04 popularity** during an active AUR build-script campaign. Nearly
   nobody on Arch is running this, so packaging breakage would land on us first. (Mitigating: the
   AUR maintainer `roceb` is also an upstream contributor.)
6. **The config *is* an arbitrary-code-execution surface in the parent process**, by design.
   Upstream is admirably candid about this — `security.md` documents the sandbox, the separate JS
   realm, and the bidirectional `Document` mirror. But `glide.process` spawns processes, and a
   chezmoi-managed `glide.ts` makes the dotfiles repo a code-delivery channel into the browser's
   main process. That is a real change to this repo's threat model, not a config file.

**Net**: Glide is the only entry that would make the *experience* meaningfully easier to configure,
and it is the only entry disqualified by its Gecko supply line rather than by packaging politics.
The gap is not a maturity gap that patience fixes — it is architectural. It closes only if upstream
does what its own docs float: move to the Firefox **release** channel and decouple Gecko bumps from
feature releases.

---

## 4. Head-to-head

| | Firefox | LibreWolf | Zen | Floorp | Waterfox | Glide |
|---|---|---|---|---|---|---|
| Arch source | `extra` | **`extra`** (1 day old) | AUR (tarball) | AUR | AUR | AUR (tarball) |
| Trust tier | Official | Official | true AUR | true AUR | true AUR | true AUR (3 votes) |
| Gecko channel | release | release | release | release | **ESR** | **beta** |
| Gecko version | 153.0.3 | 153.0.3 | 153.0.3 (AUR: 153.0.1) | ~152/153 | **ESR 140** | **153.0b5** |
| Security-patch path | Mozilla | Mozilla | ~0–4 days | days | ESR line | **feature releases only** |
| Maturity | stable | stable | all releases `b` | stable | stable | **alpha (`0.1.63a`)** |
| Bus factor | — | Arch + upstream | team | team | 1 | **1 (98% of commits)** |
| Approvals/week | 0 | 0 | **~2** | ~0.5 | ~0.3 | ~0.25 |
| `userChrome.css` ports | — | **✅ 1:1** | ❌ rewrite | ❌ rewrite | ✅ mostly | ✅ likely (unverified) |
| `legacyUserProfileCustomizations` needed | yes | yes | n/a | n/a | yes | **no — on by default** |
| Ships own `policies.json` | no | **yes (18 KB)** | yes | unverified | unverified | **no** |
| Declarative config file | no | `.overrides.cfg` | no | no | no | **`~/.config/glide/glide.ts`** |
| Per-profile config | no | no | no | no | no | **yes** |
| Multi-profile mechanism | `profiles.ini` | `profiles.ini` | `profiles.ini` | `profiles.ini` + containers | `profiles.ini` | `profiles.ini` |
| Makes profiles easier | — | **no** | **no** | marginally | **no** | **no** (but composes well) |

---

## 5. Findings

1. **No Firefox fork makes multi-profile management easier.** Every one of them inherits Gecko's
   `profiles.ini` / `MOZ_LEGACY_PROFILES` / dedicated-profiles machinery unchanged. The 866-line
   plan is not work that a browser switch avoids — the plan is valid regardless of which of these
   you run, needing only a path change. **This is the direct answer to the question that prompted
   the research: entrenchment is not the risk it looks like, because the entrenchment is in Gecko,
   not in Firefox-the-product.**
2. **The forks' pitch is UI (Zen, Floorp), hardening (LibreWolf, Mullvad), or input model (Glide).**
   Only two are configuration-management improvements: `librewolf.overrides.cfg` marginally, and
   **Glide's `glide.ts` substantially**.
3. **The theming investment picks the shortlist.** 2744 lines against Firefox chrome IDs means
   Zen and Floorp cost a full theme-system rewrite ×8 before delivering anything.
4. **Right now, AUR-only is disqualifying for a browser** given an active third-wave build-script
   campaign and demonstrable staleness on the exact packages in question.
5. **LibreWolf is the only candidate that improves the security posture without a theme rewrite** —
   but it is a one-day-old channel with PGO removed, RFP fighting the theme system, DRM off, an
   unsettled XDG path, and a `policies.json` merge to get right.
6. **Configuration ergonomics and Gecko freshness are anti-correlated in this field.** The two
   entries designed for declarative, per-profile, text-file configuration are the two furthest from
   Mozilla's release channel — Glide on beta with no out-of-band patch path, Waterfox on ESR 140.
   The entries riding Mozilla's release channel offer the least configurability. Nothing here is
   both.
7. **Off-release is survivable; *unpatched* is not — and Mullvad proves the distinction.** It sits
   on ESR 140.13.0 yet explicitly backports Firefox 153 security fixes out of band, on a monthly
   cadence. So "not on release" is not itself the objection to Glide (§3.5); shipping Gecko bumps
   *only inside feature releases*, with none cut in six weeks, is. This is the criterion to hold
   Glide to when revisiting.
8. **The field is now enumerated, not sampled.** All 25 entries under AlternativeTo's
   `firefox-based` tag were triaged (§3). Five needed evaluation; two are dead, four are
   mobile-only, three Windows-only, two pre-Quantum, one is not a browser. There is no sixth
   candidate hiding in this space — further search is unlikely to pay.
9. **Doing nothing is a strong option.** Firefox 153.0.3 in `extra`, zero approvals, CSS that
   already works, policies purely additive.

---

## 6. Must verify before any switch

The plan's `MOZ_LEGACY_PROFILES` + XDG design has to be re-proved per browser — Task 2 Step 6's
throwaway-`$HOME` picker test is exactly the right instrument, reusable as-is:

```sh
# Is LibreWolf's XDG profile root ~/.config/librewolf/librewolf/ or ~/.librewolf/?
TESTHOME="$(mktemp -d)"
env HOME="$TESTHOME" librewolf -no-remote -CreateProfile "probe" 2>&1
find "$TESTHOME" -name profiles.ini

# Does MOZ_LEGACY_PROFILES still reach the classic picker?
env HOME="$TESTHOME" MOZ_LEGACY_PROFILES=1 librewolf -no-remote

# Do our chrome selectors still resolve? (27 selectors, catppuccin-mocha as probe)
#   Browser Toolbox → inspect #TabsToolbar, #back-button, .tabbrowser-tab[selected]

# Confirm the extra/ package really is preferred over chaotic-aur once synced
sudo pacman -Sy && pacman -Si librewolf | head -3

# Glide: what Gecko does the *shipped* build actually run? (about:support, or:)
curl -s https://raw.githubusercontent.com/glide-browser/glide/main/firefox.json | jaq -r '.version'
curl -s https://api.github.com/repos/glide-browser/glide/releases/latest | jaq -r '.tag_name, .published_at'
```

Also unresolved:

- Exact merge strategy for our 19 policy keys vs LibreWolf's shipped policy — which side wins per
  key, and how the `run_onchange` script stops clobbering a package-owned file.
- Whether disabling RFP (needed for theming) removes enough of LibreWolf's value to make the whole
  switch pointless.
- Whether `extra/librewolf` survives as a maintained channel, or is a one-off fix for the AUR
  freeze that decays once the AUR reopens.
- Whether Glide's chrome really is additive enough for the 27 selectors (Browser Toolbox probe),
  and whether its `.desktop` `StartupWMClass` is `glide-glide` or `Glide Browser` — the packaged
  file sets **both**, which matters for `session-browsers.conf` and Hyprland `windowrules`.

---

## 7. Recommendation

**Execute the profiles plan on Firefox as written. Do not switch now.**

The plan is browser-portable — it is Gecko machinery, not Firefox machinery — so executing it
costs nothing in optionality. Switching first would mean re-verifying every empirical claim in
Appendix A against a browser whose packaging is one day old.

Then, **separately and later**, evaluate LibreWolf as a swap with a scope of exactly four items:
path change, `policies.json` merge, `librewolf.overrides.cfg` for RFP/DRM, and a re-run of the
plan's Task 6 verification gate. Not before `extra/librewolf` has a few weeks of history.

**Zen and Floorp are refused on supply chain and theming cost, not on quality.** If the appeal is
Zen's workspaces rather than its packaging, the cheaper experiment is Firefox's own Multi-Account
Containers — same isolation model Floorp pins to workspaces, zero packaging risk, no theme rewrite.

**Glide is refused on Gecko freshness, and it is the one worth actually wanting.** It is the only
entry that would improve how we *configure* a browser rather than how it looks or what it strips.
But an alpha on the Firefox beta channel, whose only Gecko delivery vehicle is a monthly feature
release that has not shipped in six weeks, cannot hold a work profile's session cookies. Track it —
this is a "not yet", not a "no".

If the pull is the keyboard model rather than Glide specifically, that part is separable and
costs nothing: **Tridactyl or Vimium-C on Firefox** via the existing `firefox_policies.json`
`ExtensionSettings` block gets modal/hint navigation onto the current, patched, `extra`-signed
browser today. It does not get the TypeScript config file, which is the genuinely novel part.

### When to revisit

- `extra/librewolf` has sustained maintenance and PGO restored →
  `curl -s https://archlinux.org/packages/extra/x86_64/librewolf/json/ | jaq -r '.pkgver, .build_date, .flag_date'`
- AUR adoption/push restrictions lifted and the campaign closed out → then re-score Zen, Floorp, Glide.
- Zen ships profile-per-space (`zen-browser/desktop#11646`) → changes the calculus materially,
  since that would be the first thing in this field that beats `profiles.ini` rather than wrapping it.
- Waterfox 6.7 ships on ESR 153 → its engine gap closes; the CWS-extension concern does not.
- **Glide moves to the Firefox release channel** (upstream floats this in `docs/firefox.md`) **and**
  decouples Gecko bumps from feature releases, **and** leaves alpha → then it becomes the strongest
  candidate in this document, because its configuration model is the only real improvement found.
  Watch `firefox.json` `.version.product` flipping `firefox-dev` → release:
  `curl -s https://raw.githubusercontent.com/glide-browser/glide/main/firefox.json | jaq -r '.version'`

---

## Sources

- [Arch `extra/librewolf`](https://archlinux.org/packages/extra/x86_64/librewolf/) ·
  [`extra/firefox`](https://archlinux.org/packages/extra/x86_64/firefox/)
- [LibreWolf: Arch official repo discussion (issues#3159)](https://codeberg.org/librewolf/issues/issues/3159) ·
  [shipped policies.json](https://codeberg.org/librewolf/settings) ·
  [settings docs](https://www.librewolf.net/docs/settings/) · [FAQ](https://librewolf.net/docs/faq/)
- [AUR malware wave analysis, Corgea](https://corgea.com/research/arch-aur-openconnect-sso-malware-wave-august-2026) ·
  [Linuxiac](https://linuxiac.com/arch-linux-disables-aur-package-adoption-amid-malicious-takeovers/) ·
  [FOSS Force](https://fossforce.com/2026/07/new-attack-puts-archs-aur-into-lockdown-again/)
- [zen-browser/desktop releases](https://github.com/zen-browser/desktop/releases) ·
  [profile-per-space discussion #11646](https://github.com/zen-browser/desktop/discussions/11646) ·
  [Zen docs](https://docs.zen-browser.app/faq)
- [Floorp Workspaces docs](https://docs.floorp.app/docs/features/workspaces/) ·
  [12.16 release notes](https://blog.floorp.app/en/release/12.16.0/)
- [Glide](https://glide-browser.app) · [glide-browser/glide](https://github.com/glide-browser/glide) ·
  [`firefox.json` (Gecko pin)](https://github.com/glide-browser/glide/blob/main/firefox.json) ·
  [docs/firefox.md (beta-channel rationale)](https://github.com/glide-browser/glide/blob/main/src/glide/docs/firefox.md) ·
  [docs/config.md](https://github.com/glide-browser/glide/blob/main/src/glide/docs/config.md) ·
  [docs/security.md](https://github.com/glide-browser/glide/blob/main/src/glide/docs/security.md) ·
  [announcement post](https://blog.craigie.dev/introducing-glide/)
- [Waterfox changelog](https://www.waterfox.com/releases/) ·
  [Mullvad Browser profile discussion](https://discuss.privacyguides.net/t/benefit-of-using-multiple-profiles-on-mullvad-browser/18096)
- Field sweep: [AlternativeTo `firefox-based` tag](https://alternativeto.net/browse/all/?tag=firefox-based)
  (25 entries, 2026-08-08)
- [Mullvad Browser](https://github.com/mullvad/mullvad-browser) ·
  [15.0.19 notes (ESR 140.13.0 + FF153 backports)](https://github.com/mullvad/mullvad-browser/releases/tag/15.0.19) ·
  [hard facts](https://mullvad.net/en/browser/hard-facts) ·
  [letterboxing warning #44](https://github.com/mullvad/mullvad-browser/issues/44) ·
  [letterboxing pref #355](https://github.com/mullvad/mullvad-browser/issues/355)
- [FireDragon 13](https://gitlab.com/garuda-linux/firedragon/firedragon13) ·
  [Pulse Browser (archived)](https://github.com/pulse-browser/browser) ·
  [Dot Browser](https://github.com/dothq/browser)
- [Mozilla `firefox_versions.json`](https://product-details.mozilla.org/1.0/firefox_versions.json)
  — release/ESR/beta reference points
- Local: AUR RPC v5 `info` endpoint, `pacman -Ql firefox`, `pacman -Si librewolf`,
  `aur.archlinux.org/cgit` PKGBUILD for `zen-browser-bin`, `mullvad-browser-bin`, `icecat`,
  `firedragon`
