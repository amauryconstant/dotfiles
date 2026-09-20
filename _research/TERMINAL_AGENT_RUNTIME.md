# Terminal / Agent Runtime — Decision Record

**Source**: Herdr v0.9.0, shallow clone of `github.com/herdrdev/herdr` (Apache-2.0), read at source level. **Not vendored** — see "Reproducing this research".
**Created**: 2026-09-13
**Purpose**: Decide what owns the terminal layer and what owns the agent layer, now that coding agents changed the requirement the 2026 Ghostty migration was planned against.
**Status**: Research complete. No integration performed. Decision pending.

**See**: `_plans/archive/ZELLIJ_TO_GHOSTTY_MIGRATION.md` (the plan this amends) · `private_dot_local/lib/scripts/system/CLAUDE.md` → "Package Security Policy"

---

## The question

Three candidates have been proposed for one layer, at three different times:

1. **Zellij** — installed, configured, in use.
2. **Ghostty-native, no multiplexer** — planned, Phases 1–2 live, Phases 3–4 written and gated.
3. **Herdr** — proposed 2026-09-13.

They are not interchangeable, and the third is not a multiplexer in the sense the other two are. This document separates the *terminal* question from the *agent* question, because conflating them is what makes the choice look harder than it is.

---

## Summary of findings

| Claim | Verdict |
|---|---|
| Herdr replaces Ghostty | **False.** Herdr runs inside a terminal emulator. Ghostty is unaffected under every option. |
| Herdr replaces Zellij | True, but that is the least interesting thing about it. |
| "Close the lid and they keep working" | **False on this machine.** See "The claim that does not survive". |
| Herdr's advantage is persistence | **False.** Its persistence is comparable to Zellij's for the case that matters. |
| Herdr's advantage is agent state detection | **True**, and it is the only driver that survives scrutiny. |
| Detection is a protocol integration | **False.** It is screen-scraping of rendered TUI chrome, updated over the network. |
| `_plans/archive/ZELLIJ_TO_GHOSTTY_MIGRATION.md` → "What is lost at cutover": "detach/reattach — unused" | **False.** `zellij a <session>` was in use. The plan records an incorrect premise. |

---

## Part 1 — The layer as it stands

**Zellij surface in this repo** (what a removal would touch):

| Path | Role |
|---|---|
| `.chezmoidata/packages.yaml:173` | the package |
| `private_dot_config/zellij/config.kdl` | `default_mode "locked"`, `on_force_close "detach"`, 50k scrollback |
| `private_dot_config/zellij/layouts/{coding,agentic-coding,monitoring}.kdl` | declarative startup layouts |
| `private_dot_config/zellij/themes/symlink_default.kdl.tmpl` | theme symlink |
| `private_dot_config/themes/*/zellij.kdl` | 8 colorsets |
| `private_dot_local/lib/scripts/desktop/executable_theme-apply-zellij` | + its hook in `executable_theme-switcher.tmpl` |
| `private_dot_config/zsh/dot_zshrc.d/zellij-layouts.zsh.tmpl` | 99 lines: `zdl`, chpwd auto session-rename |
| `private_dot_config/zsh/dot_zshrc.d/zellij-completions.zsh` | completions |
| `private_dot_local/lib/scripts/terminal/executable_zellij-sessionizer.tmpl` | fzf project picker |
| `private_dot_config/zsh/dot_zshrc.d/aliases.zsh:30` | `alias zj` |
| `private_dot_config/hypr/conf/bindings/applications.{lua,conf}.tmpl:24` | `SUPER+O` |
| `private_dot_config/nvim/lua/plugins/user.lua:3-28` | `zellij-nav.nvim`, `image.nvim` sixel ternary |

**Ghostty-native trial**: `executable_ghostty-sessionizer.tmpl` on `SUPER+SHIFT+O`, splits confirmed native, nothing zellij-owned removed. Phases 3–4 written but gated on an explicit go-ahead that was never given.

---

## Part 2 — The workload changed under the plan

The migration plan accepts four losses at cutover (`:86-93`). One of them is now wrong and one is now load-bearing.

**`:88` — "Live detach/reattach — unused (workflow rebuilds from scratch)."**

Incorrect as written: `zellij a <session>` was in regular use. The plan reasons from a premise that does not hold, and Phase 4 would therefore remove a capability the plan believes is already dead.

**The reason it matters more now than it did then.** The plan was written for a human-at-keyboard workflow, where rebuilding a workspace from nvim each morning is cheap and a stale reattach is worse than a fresh start. Agents are the first workload here that runs *unattended for long stretches across several projects at once*. Rebuild-from-scratch is not a neutral default for a process you walked away from; it is data loss.

**Current cost, measured by self-report**: finding out whether an agent is blocked or finished is done by **cycling Ghostty tabs by hand**. There is no signal. That is the pain this decision is actually about, and it is an attention cost paid repeatedly, all day.

**Workload shape**: agents run across separate repositories *and* across git worktrees of the same repository, roughly evenly. Any grouping model has to express both axes.

---

## Part 3 — Herdr, read at source level

252,809 lines of Rust across 343 files. Apache-2.0. v0.9.0 (`Cargo.toml`).

### It is built on Ghostty's terminal engine

`build.rs:54-99` vendors **`libghostty-vt`** and builds it with Zig 0.16.0. `src/ghostty/bindings.rs` (5,275 lines) is the generated FFI surface.

This is the most under-advertised fact about Herdr for this machine specifically. Zellij implements its own VT; Herdr runs Ghostty's. A Ghostty user gets identical terminal semantics inside and outside the multiplexer — the class of bug where a TUI renders correctly in the terminal and wrongly inside the multiplexer largely disappears, because it is the same parser.

`src/kitty_graphics/` also exists, which resolves an open question from the migration plan: the Kitty graphics protocol is handled, so `image.nvim` would not be forced onto sixel the way it is inside Zellij.

### Agent state detection is screen-scraping

`src/detect/mod.rs:1-4`, the module's own doc comment:

> Agent state detection via terminal tail pattern matching. Each pane's live bottom-of-buffer text is read periodically and matched against known agent output patterns to determine state.

`src/detect/mod.rs:11` defines the states: `Idle`, `Working`, `Blocked`, `Unknown`.

22 agent manifests ship in `src/detect/manifests/`. `claude.toml` is roughly 200 lines of prioritised rules matching Claude Code's **rendered chrome**: `esc to interrupt`, `do you want to proceed?`, `tab to amend`, `ctrl+e to explain`, the `❯` selection marker, and the braille-range spinner codepoints. Only two rules read anything resembling a protocol — `region = "osc_title"` and `region = "osc_progress"`.

Three consequences follow, and they are structural rather than incidental:

1. **Detection is coupled to each agent's UI version.** The manifest carries `version = "2026.09.11.1"` and `min_engine_version = 2`. Its own comments cite upstream breakage issues (`#3283` for MCP elicitation dialogs, `#2650` for Bash permission prompts whose resting layout went unmatched). Every agent TUI change is a chance for state detection to go wrong.
2. **The failure mode is silent and inverted.** A stale rule set does not report an error; it reports `Idle` for an agent that is actually `Blocked`. The tool's entire value is telling you where to look, so a wrong answer is worse than no answer — you stop checking.
3. **The rules update themselves over the network**, which is the subject of Part 5.

To be fair to the design: there is no alternative available. Agent CLIs expose no state protocol, and the OSC title/progress rules show Herdr using real signals wherever an agent emits any. Screen-scraping is the only mechanism that could work today. The point is not that Herdr chose badly — it is that this is a maintenance treadmill the user inherits, not a stable integration.

### Persistence is weaker than the marketing

`docs/versions/0.9.0/website/src/content/docs/session-state.mdx:13`, upstream's own table:

| Case | Processes keep running | Layout returns | Recent screen returns | Agent conversation resumes |
| --- | --- | --- | --- | --- |
| Detach and reattach | Yes | Yes | Yes, from the live terminal | Yes, because the process never stopped |
| Server restart | **No** | Yes | Only with pane screen history | Only with native agent session restore |

Read carefully, the persistence story is:

- **Detach/reattach**: processes survive. This is exactly what Zellij already does, and what was already in use here via `zellij a <session>`.
- **Server restart**: processes **do not** survive. What returns is the *shape* — workspaces, tabs, panes, cwd, focus — with panes respawned as new shells in their saved directories.
- **Screen contents** across a restart require `[experimental] pane_history = true`, which is **off by default** and which upstream itself flags as storing secrets, tokens and command output to `session-history.json`.
- **Agent conversation resume** across a restart depends on the agent's own session-resume feature, not on Herdr.

### Worktrees are first-class

`src/worktree.rs` (954 lines) creates and tracks git worktrees, generating branch slugs from an adjective/noun table, and tracking `branch`, `is_bare`, `is_detached`, `is_prunable`. Given a workload split evenly between repositories and worktrees, this is a genuine fit that neither Zellij nor Ghostty splits offer.

### Remote

`src/remote/` — `attach.rs`, `host.rs`, `process.rs`, `restart_policy.rs`, `saved.rs`. Remote attach pushes a binary to the target host and verifies it by sha256 (`src/remote/attach.rs:1914`).

---

## Part 4 — The claim that does not survive

Herdr's headline promise is *"walk away and they keep working"*.

**This machine suspends.** When hypridle suspends the laptop, every agent stops — Herdr's server included. Persistence across a *client disconnect* is not persistence across a *host suspend*, and no multiplexer can bridge that gap. Zellij, tmux and Herdr lose equally.

So the "persistence" driver is not deliverable locally by any candidate in this comparison. Its only real answers are:

1. **Inhibit idle while agents run.** The repo already ships `desktop/idle-toggle` and `desktop/idle-toggle-nolock`. This is a habit, not a feature, and it costs battery.
2. **Run agents on a host that does not sleep.** This is the SSH/remote path, deferred twice on the assumption that local persistence worked. That assumption is now known to be false, which is why the remote angle is promoted to a first-class option rather than a "maybe later".

**Net effect on the case for Herdr**: one of the two stated drivers is struck out — not because Herdr fails at it, but because nothing at this layer can succeed at it here. What remains is agent state detection, which is real, and which the current workflow pays for in manual tab-cycling.

---

## Part 5 — What adopting it would cost this repo

### Three network surfaces, against the strictest policy in this codebase

The Package Security Policy gates AUR build-file changes behind a manual `package-manager approve`. Herdr introduces channels that change behaviour *after* installation, outside that gate.

| Surface | Endpoint | Verification | Toggle |
|---|---|---|---|
| Detection manifests | `https://herdr.dev/agent-detection/index.toml` (`src/detect/manifest_update.rs:16`) | **None found.** No checksum or signature path in that module; TLS only | `[update] manifest_check = false` |
| Binary self-update | `https://herdr.dev/latest.json` (`src/update.rs:25`) | sha256 verified (`src/update.rs:658`, `:741`) — but the hash ships in the same fetched JSON, so this is corruption integrity, not provenance | `[update] version_check = false` |
| Plugin marketplace | `github.com` clones | not examined | do not install plugins |

Both update defaults are **on** (`src/config/model.rs:33-45`: `version_check: true`, `manifest_check: true`). Both are toggleable in `config.toml`. The manifest catalog also honours `HERDR_AGENT_DETECTION_MANIFEST_CATALOG_URL` (`src/detect/manifest_update.rs:17`), cached under `state_dir()/agent-detection` (`:498`).

Severity, stated honestly: the manifest channel delivers **regex data, not code**. It cannot execute. Its realistic worst case is degraded or manipulated state reporting, plus whatever a hostile regex can do to a matcher. That is not a critical vulnerability; it *is* a behaviour-changing channel that bypasses this repo's own review gate, and the repo has a written policy about exactly that class of thing.

### Self-update collides with pacman

`src/update.rs:1981-1985` — `is_package_manager_managed_exe_path()` recognises **homebrew, mise and nix**. It does not recognise pacman, AUR, apt or dnf. An AUR-installed `herdr-bin` at `/usr/bin/herdr` is therefore not detected as package-managed, and `herdr self-update` would attempt to overwrite a pacman-owned file rather than refusing with the guidance it gives brew and nix users.

Mitigation is trivial (`version_check = false`, never invoke `self-update`) but it must be written down, because the default is the opposite.

### Packaging

| Package | Version | Votes / popularity | Note |
|---|---|---|---|
| `herdr-bin` | 0.9.0-1 | 14 / 6.35 | prebuilt from GitHub releases — the viable option |
| `herdr` | 0.8.2-1 | 3 / 1.70 | source build, **flagged out-of-date** |
| `herdr-git` | — | 0 | would need a vendored `#commit=` per the pinning policy |
| `herdr-corral-bin` | 0.1.9-1 | 0 | third-party plugin, unrelated |

All are true-AUR tier: tripwire gate plus `package-manager approve herdr-bin` on first sync and on every PKGBUILD change. Note that for a `-bin` package the review covers the download URL and hash, never the binary itself. Building from source is possible but requires Zig 0.16.0 for the vendored libghostty-vt, and the source package is already lagging.

### Maturity

v0.9.0, pre-1.0, with an in-tree `docs/next` and `docs/preview` indicating active churn. The AUR source package being flagged out-of-date while the `-bin` tracks 0.9.0 is consistent with a fast release cadence.

### Theming and configuration

`config.toml`, TOML. Built-in themes selectable by name with `[theme] name`, individual colours overridable under `[theme.custom]` in hex/named/`rgb()`. There is an `auto_switch` option that must stay **off** — darkman owns light/dark switching in this repo, and a second switcher would fight it.

Porting the 8 colorsets would mean 8 new per-theme fragments plus a `theme-apply-herdr` hook in `executable_theme-switcher.tmpl`, mirroring what `theme-apply-zellij` does today.

---

## Part 6 — Scoring against the two stated drivers

| | Zellij | Ghostty-native (Phase 4 end state) | Herdr |
|---|---|---|---|
| Agent state visible without checking | No | No | **Yes** (screen-scraped, maintenance-coupled) |
| Processes survive client disconnect | Yes | **No** — `window-save-state` is macOS-only | Yes |
| Processes survive host suspend | No | No | No |
| Worktree-aware | No | No | **Yes** |
| Same VT engine as the terminal | No | n/a (is the terminal) | **Yes** (vendored libghostty-vt) |
| Kitty graphics in panes | No (sixel) | n/a | Yes |
| Added network surfaces | None | None | Three, two on by default |
| Maturity | stable | n/a | v0.9.0 |

The Phase 4 end state scores zero on both stated drivers. That is the finding that reopens a plan which was otherwise ready to execute.

---

## Part 7 — Position and return conditions

**Position**: the terminal question and the agent question should be answered separately, and only the agent question is actually open.

- **Terminal layer** — the Ghostty-native migration remains correct for interactive work. Its rationale (native splits, no multiplexer tax, layouts inside nvim) is unaffected by anything in this document. Phase 3 (`zellij-nav.nvim` → `smart-splits.nvim`) is a no-regret move under every option, because `smart-splits.nvim` supports tmux, zellij, wezterm, kitty **and herdr** (`multiplexer_integration = 'herdr'`, with upstream shipping `herdr-plugin.toml` and `scripts/herdr-navigate.sh`). It works under all three candidates simultaneously.
- **Agent layer** — Herdr is the only candidate that addresses the measured pain. It should be scoped as the agent layer only, not as a Zellij replacement, which keeps its blast radius to agent panes and leaves interactive work on the path already planned.

**What would make this a yes**, any one of:

1. Manual tab-cycling cost becomes concrete enough to name — e.g. an agent sits blocked long enough to matter more than once in a week.
2. The remote/SSH path is wanted for real, at which point Herdr's remote support answers the persistence driver that nothing local can.
3. Herdr reaches 1.0 with a stable detection-manifest story.

**What would make this a no**:

1. Detection proves unreliable in practice for Claude Code specifically — the scraping rules are the product, and a wrong `Idle` is worse than no sidebar.
2. The three network surfaces cannot be reconciled with the Package Security Policy to the user's satisfaction. Note this is a judgement call, not a technical blocker: all are toggleable.
3. Agent workload drops back to one-at-a-time, at which point there is nothing to supervise.

**Revisit trigger**: Herdr 1.0, or the first time an agent is found blocked for longer than it should have been.

---

## Part 8 — Future perspectives

**Agent state on the Quickshell bar.** Noted, not scoped. Herdr's socket API could feed a bar widget or the notification server this repo already owns, which would answer "how do I find out an agent is blocked" without a sidebar to watch at all — arguably a better fit than Herdr's own TUI, given the surfaces already built. The Quickshell build closed 2026-09-13 and this document does not propose reopening it.

**Scripted orchestration.** `herdr agent wait <pane> --until done` blocks a shell on an agent completing. Combined with `herdr workspace create --cwd`, `herdr pane split` and `herdr pane run`, agent orchestration becomes shell-scriptable — which is a question about this repo's script library, not about the terminal layer, and deserves its own research thread if it is wanted.

**Remote.** Promoted from "maybe later" by the suspend finding. Would need its own pass against the Package Security Policy: a server plus socket API reachable over SSH, with binary push-and-verify (`src/remote/attach.rs:1914`) as its install mechanism on the far side.

---

## Reproducing this research

The source was **not** vendored into `_ai/`, by decision — a large Rust tree should not be committed for a tool that has not been adopted. To re-read it:

```sh
git clone --depth 1 https://github.com/herdrdev/herdr.git
```

Every `file:line` citation above is against **v0.9.0** and will drift. Upstream docs are vendored inside that clone at `docs/versions/0.9.0/website/`, including an authoritative `src/data/config-reference.json` — prefer those over the website, which tracks `next`.

If the decision comes out in Herdr's favour, vendor it into `_ai/` per `_guides/VENDORED_SUBTREES.md` so these citations become durable.
