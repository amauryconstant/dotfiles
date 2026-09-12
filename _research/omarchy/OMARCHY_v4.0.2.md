# Omarchy v4.0.2 — Release Research

**Date researched**: 2026-09-12
**Previous version**: v4.0.1
**Commits**: 28
**Source**: Commit log fallback

---

## Summary

A security-hardening point release: nearly every change closes a privilege or injection path
rather than adding behaviour. The largest themes are browser-policy directory ownership (they
were world-writable at `a+rw`), removal of blanket `input` group membership, SSH password
authentication being disabled once a key is authorized, a rewritten `omarchy-windows-vm` that
bind-mounts pinned inodes onto root-owned anchors, and CUPS printer discovery being hardened
and then temporarily removed entirely. Ten migrations ship with it, and the test tree grows by
roughly 10k lines including two new repo-wide scanners (privileged heredocs, QML `textFormat`).

## Breaking Changes

- **Automatic printer discovery removed**: `cups-browsed` is uninstalled and its package dropped
  from `install/omarchy-base.packages`. Migration `1788009111.sh` disables the unit, removes idle
  `implicitclass://` queues (leaving queues with pending jobs alone), and removes the package.
  Printers must be added by hand from Print Settings. `manual/46-faq.md` rewritten accordingly.
- **`cups-pdf` removed** from the base package list, replaced by `cups-pk-helper`.
- **`input` group grant removed**: `install/hardware/input-group.sh` deleted and dropped from
  `install/hardware/all.sh`. Migration `1787865477.sh` removes existing membership unless
  `xpadneo-dkms` or `ydotool` is installed. Membership of `input` allowed unprivileged keylogging
  and input synthesis via `/dev/input/event*`. `omarchy-provision-owner` applies the same
  predicate at first-boot user creation.
- **SSH password authentication disabled**: `omarchy-setup-security-sshd` now writes
  `/etc/ssh/sshd_config.d/10-omarchy-hardening.conf` with `PasswordAuthentication no` +
  `KbdInteractiveAuthentication no` after a key is authorized. Migration `1788124236.sh` applies
  this to existing installs, and disables sshd itself when no key is authorized.
- **`omarchy-asdcontrol` sudoers rule deleted**: `etc/sudoers.d/omarchy-asdcontrol` removed
  (`%wheel NOPASSWD: /usr/bin/asdcontrol`).
- **Theme names are now character-restricted**: `omarchy-theme-install` requires
  `^[a-z0-9_][a-z0-9._+-]*$` under `LC_ALL=C`. Repos whose derived name contains a space, quote or
  non-ASCII character are refused at install time.
- **Web app names may not contain `/`**: `omarchy-webapp-install` refuses them; web app URLs must
  be `http`/`https` with no whitespace.
- **Omarchy repo packages must be signed**: `SigLevel = Optional TrustAll` removed from all three
  pacman configs; migration `1787589206.sh` drops the override on existing installs.

## Features

- **`omarchy-theme-set-browser-policy`**: new privileged single-purpose writer for browser
  `color.json`. Accepts exactly six lowercase hex digits, re-execs itself via `sudo` or `pkexec`,
  pins `PATH` to system directories when root, and writes only into already-existing policy dirs.
  Omarchy path: `bin/omarchy-theme-set-browser-policy`, `etc/sudoers.d/omarchy-theme-browser`.
- **Browser policy helper library**: shared dir/parent lists and hardening routine used by the
  installer, the migration, `omarchy-install-browser` and `omarchy-provision-owner`.
  Omarchy path: `install/helpers/browser-policy.sh`, `install/config/browser-policy.sh`,
  `install/helpers/as-root.sh`.
- **`rc` package channel**: `omarchy-version-channel` recognizes `https://pkgs.omarchy.org/rc/`;
  `pacman-rc.conf` repointed from the edge repo to the dedicated rc repo. Migration
  `1788112314.sh` repoints existing rc-mirror machines. Omarchy path:
  `default/pacman/pacman-rc.conf`, `bin/omarchy-version-channel`.
- **Plymouth refresh modes**: `omarchy-plymouth-set` gains `--refresh-default` and
  `--refresh-sddm-default`, refuses to run as root, and opens the logo file descriptor while
  unprivileged before publishing to `/usr/share`. Omarchy path: `bin/omarchy-plymouth-set`.
- **Privileged-heredoc scanner**: new `test/shell.d/privileged-heredoc-test.sh` plus ~30 fixtures
  flags heredocs written to privileged destinations that expand a `$HOME`-derived path. Scripts
  opt out with an `# omarchy:heredoc-expands paths=none -- <reason>` annotation (used in
  `omarchy-dns`, `omarchy-setup-security-fingerprint`, `omarchy-upgrade-to-quattro`,
  `omarchy-windows-vm`).
- **QML `textFormat` scanner**: `test/shell.d/qml-text-format-scan.py` reports every `Text` element
  rendering a non-literal value without an explicit `textFormat`. ~30 shell QML files annotated as
  a result.

## Bug Fixes

- **Notification `<img>` stripping was bypassable**: the old `/<img[^>]*>/gi` regex operated on
  substrings, so `<im<img src="http://a/decoy.png">g src="http://a/beacon.png">` was *rewritten
  into* a live image tag. Replaced with a whole-tag scanner (`stripImageTags`) that matches Qt's
  `QQuickStyledText` name-reading rules, plus a `styledBody()` that re-strips after the newline →
  `<br/>` rewrite. StyledText `<img src>` caused unauthenticated HTTP GETs with no user action.
  Omarchy path: `shell/plugins/notifications/NotificationLogic.js`,
  `shell/plugins/notifications/components/NotificationCard.qml`.
- **Chromium 151 first-run EULA**: `require_eula:false` added to
  `/usr/lib/chromium/initial_preferences`. Migration `1787691200.sh` retrofits machines already on
  Quattro. Omarchy path: `install/config/theme-system.sh`, `bin/omarchy-upgrade-to-quattro`.
- **scp-style theme URL parsing**: `git@host:omarchy-blue-theme.git` (no slash after the colon)
  was read as a whole-URL theme name. Omarchy path: `bin/omarchy-theme-install`.
- **Codex usage collection on 0.149**: `-a untrusted` → `-a on-request`. Omarchy path:
  `bin/omarchy-agent-usage-codex`.
- **Migration runner consumed migration stdin**: the `while read` loop now uses fd 3 and closes it
  for the child (`bash … 3<&-`). Omarchy path: `bin/omarchy-migrate`.
- **`omarchy-plymouth-reset` exit status**: `set -euo pipefail` added and both helpers invoked
  through `$OMARCHY_PATH/bin/` instead of by bare name. Omarchy path: `bin/omarchy-plymouth-reset`.
- **Apple display brightness cache**: cache written under `$XDG_RUNTIME_DIR` only (no `/tmp`
  fallback), and a cached value is only trusted if it still matches `/dev/hiddev*` or
  `/dev/usb/hiddev*` and is a character device. Omarchy path:
  `bin/omarchy-brightness-display-apple`.
- **Upgrade ordering**: `run_post_upgrade_migrations` moved after
  `run_final_system_package_upgrade`, now hard-fails instead of warning, and verifies
  `omarchy-migrate --pending` reports nothing left. Omarchy path:
  `bin/omarchy-upgrade-to-quattro`.
- **Autologin cleanup unit heredoc**: unquoted heredoc replaced with a quoted one plus `sed
  s|@UNIT@|…|`. Omarchy path: `bin/omarchy-provision-owner`.

## Improvements

- **Shell quoting in launcher wrappers**: `omarchy-install-app` and `omarchy-install-font` now
  `printf %q` their arguments the way `omarchy-install-and-launch` does; all three split the
  package list into words before quoting each. `omarchy-menu.jsonc`'s `style.unlock` action wraps
  the picker result in `printf %q`.
- **Desktop entry escaping**: `omarchy-webapp-install` gains `desktop_string_escape()` (Desktop
  Entry string escaping — backslash, tab, CR, LF, leading space) and `desktop_exec_arg()` (Exec
  spec double-quoted argument). A raw newline in the name previously injected a second `Exec=`.
- **Windows VM mount boundary**: `bin/omarchy-windows-vm` rewritten (~1000 lines changed). The
  privileged path no longer accepts host volume paths from the compose file; it derives both
  anchors from the authenticated uid, opens and pins the source directory FDs, and bind-mounts
  the exact inodes onto root-owned anchors under `/var/lib/omarchy/windows/mounts`. Adds bounded
  containment checks before removal, `0700` on disk/shared directories, atomic credential file
  writes, pinned `PATH`/locale in the privileged process, and web console (port 8006)
  authentication with the configured Windows username and password.
- **CUPS hardening** (shipped, then superseded by the removal above): `cups-browsed` moved to its
  own `cups-browsed` system user with a `CacheDir` of `/var/cache/cups-browsed`, a systemd
  drop-in with `NoNewPrivileges`/`ProtectSystem=strict`/`ProtectHome`/`PrivateTmp`/
  `RestrictSUIDSGID`, and `CreateIPPPrinterQueues Driverless` +
  `CreateRemoteCUPSPrinterQueues No`. Migration `1787815267.sh` separates discovery from
  print-filter access.
- **Legacy XCompose + Omarchy 3 power udev rules**: migration `1788102906.sh` removes udev rules
  whose `RUN+=` resolved through a user-owned `~/.local/share/omarchy` symlink (root code
  execution on a power_supply event), quarantining administrator-modified copies under a
  non-`.rules` suffix, and repoints `~/.XCompose` at the packaged file.
- **Retired installer artifacts**: migration `1788025225.sh` removes root-owned sudoers/systemd
  files left by three retired installers, comparing normalized "active lines" against what those
  installers actually produced so administrator-authored files of the same name survive.
- **Migration policy documented**: migrations are strictly ordered and synchronous; one that
  cannot finish must exit non-zero and stop the queue. Clearing a privileged file left by a
  retired installer belongs in a migration, not in the Quattro upgrade command. Omarchy path:
  `docs/migrations.md`.
- **Manual updates**: printer setup walkthrough (`manual/46-faq.md`), theme name rules
  (`manual/43-making-your-own-theme.md`), Windows VM mount/console behaviour
  (`manual/28-windows-vm.md`), and `omarchy-dev-link`'s Plymouth/SDDM exception note.

## Configuration Changes

- **Browser policy directories**: were `mkdir -p` + `chmod a+rw` (world-writable managed-policy
  roots). Now `0755 root:root`, with parent-chain checks and non-root entries purged.
  Old: `install/config/theme-system.sh` + `setup_policy_directory()` in
  `bin/omarchy-install-browser`. New: `install/helpers/browser-policy.sh`
  (`BROWSER_POLICY_MANAGED_DIRS`, `BROWSER_POLICY_PARENT_DIRS`, `browser_policy_setup_dir`,
  `browser_policy_purge_dir`). Migration `1787515927.sh` repairs existing installs.
  Firefox distribution dirs (`/usr/lib/firefox/distribution`,
  `/opt/zen-browser/distribution`) moved into the same helper.
- **tzupdate sudoers rule narrowed**: old
  `%wheel ALL=(root) NOPASSWD: /usr/bin/timedatectl set-timezone *`; new
  `… /usr/bin/timedatectl ^set-timezone [A-Za-z0-9_+][A-Za-z0-9_+.-]*(/[A-Za-z0-9_+][A-Za-z0-9_+.-]*)*$`
  — a single timezone argument only. Omarchy path: `etc/sudoers.d/omarchy-tzupdate`.
- **pacman SigLevel**: `SigLevel = Optional TrustAll` removed from `[omarchy]` in
  `default/pacman/pacman-{stable,edge,rc}.conf`; the repo now inherits the global
  `SigLevel = Required DatabaseOptional`.
- **`cups-files.conf` shipped**: new `etc/cups/cups-files.conf` with `User 209` / `Group 209`,
  `SystemGroup cups-browsed sys root`, `PeerCred on`. `install/post-install/pacman.sh` now
  installs it as `0640 root:cups` (previously it installed `cups-browsed.conf`).
- **Reserved usernames**: `cups-browsed` added to `OMARCHY_RESERVED_USERNAMES`. Omarchy path:
  `install/provisioning/setup-form.sh`.
- **Services**: `systemctl enable cups-browsed.service` removed from
  `install/config/enable-services.sh` and `bin/omarchy-upgrade-to-quattro`.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Removed | `cups-browsed` | Automatic printer discovery temporarily withdrawn; migration `1788009111.sh` uninstalls it and removes generated queues |
| Removed | `cups-pdf` | Dropped in the CUPS hardening pass |
| Added | `cups-pk-helper` | polkit-mediated CUPS administration in place of direct privileged access |
