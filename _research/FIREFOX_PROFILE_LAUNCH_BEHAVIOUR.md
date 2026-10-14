# Firefox Profile Launch Behaviour (157, Wayland + XWayland)

Measured record of how Firefox 157.0.1 selects, names and routes profiles on this machine, taken
to design the multi-profile setup in `_plans/FIREFOX_PROFILES_IMPLEMENTATION_PLAN.md`. Every
result below was observed on 2026-10-14 through the real EGL wrapper
(`private_dot_local/bin/executable_firefox`), not the bare binary. Reproduce with
`.scripts/firefox-profile-gate.sh`.

## Summary

| Question | Answer |
|---|---|
| Does `StartWithLastProfile=0` show the classic picker, and does `Default=1` preselect? | Yes to both, with `MOZ_LEGACY_PROFILES=1`. No stray `*.default-release`, `[Install]` section or `installs.ini` |
| How does a window get its own Hyprland class? | `--name X` on native Wayland, `--class X` on XWayland. Pass **both** |
| How does a URL reach the right running profile? | By profile: `-P "<Name>"` or `--profile <path>`. `--name` takes no part in routing |
| What does `-P` match? | The `Name=` in `profiles.ini`, case-sensitive. Not the directory |
| What happens on a miss? | A Profile Manager opens, with whatever class `--name`/`--class` gave it |

## Method

A throwaway profile root with two profiles, `Alpha` (`Default=1`) and `Beta`, under
`StartWithLastProfile=0`. The wrapper is run with `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and
`XDG_DATA_HOME` pointed at the throwaway tree, `MOZ_LEGACY_PROFILES=1`, and `BASH_ENV` unset.
`FIREFOX_BACKEND=x11` forces the wrapper's XWayland fallback. The class is read from
`hyprctl clients -j`, which reports the Wayland `app_id` or the X11 `WM_CLASS` `res_class`
depending on the backend.

## Results

### Picker

The classic Profile Manager appeared on a bare launch, listed exactly `Alpha` and `Beta`, and
preselected `Alpha`. Afterwards the root held `alpha`, `beta`, `profiles.ini` and Firefox's
sibling dirs (`Crash Reports`, `Pending Pings`); no `[Install]` line, no `installs.ini`.

For contrast, the machine's real root, written before `MOZ_LEGACY_PROFILES=1` was set, shows
Firefox's dedicated-profile takeover: `[Install4F96D1932A9F858E] Locked=1`, `installs.ini`, two
stub profiles and two empty `Profile Groups/*.sqlite`.

### Window class

| Flag | Native Wayland | XWayland |
|---|---|---|
| `--name firefox-X` | `firefox-X` | `firefox` |
| `--class firefox-X` | `firefox` | `firefox-X` |
| both | `firefox-X` | `firefox-X` |

The XWayland column matters: the wrapper falls back to XWayland whenever the patched egl-wayland2
build is missing, which is the state of a fresh install until
`run_after_build_egl_wayland2_patched` has run.

### Remoting (profile A and B both running, then a URL is sent)

| Send | Result |
|---|---|
| `-P Beta --new-tab URL` | Tab opens in Beta's existing window. Parent-process count unchanged. Wayland and XWayland |
| `--profile <path to beta> URL` | Tab opens in Beta. Wayland |
| URL only, no profile flag | Tab opens in **Alpha**, the wrong profile |
| `-P beta` (name case wrong) | Profile Manager and a second parent process |

## Traps found while measuring

1. **`XDG_CONFIG_HOME` beats `$HOME`.** The session exports it, and Firefox reads the profile root
   from it first. Overriding only `$HOME` silently ran the first attempt against the real root, and
   launched the real stub profile. Override all three XDG variables.
2. **`-P` is a name lookup, and a miss is quiet.** There is no error; a Profile Manager opens. Because
   `--name`/`--class` still apply to that dialog, `hyprctl` shows a plausible class. The title,
   "Choose User Profile", is what gives it away, and so does an empty profile directory.
3. **`pkill -f <test path>` kills nothing useful.** The instances' command lines hold `--name` and
   `-P`, not the path. Stale instances keep their remoting name, and a later launch with the same
   name collides with them and falls back to a Profile Manager. Match on the process environment
   instead.
4. **The wrapper reads `PATCHED_LIB` from `$HOME`.** A throwaway home must symlink
   `$HOME/.local/lib`, or the wrapper drops to XWayland and the "Wayland" run measures the wrong
   backend.
5. **The login shell's `BASH_ENV` file sources `$HOME/.config/shell/env`.** In a throwaway home it
   prints an error on every wrapper launch (harmless, but noisy).

## Consequences for the design

- Launchers and the `firefox-open` chooser pass `--name firefox-<id> --class firefox-<id> -P "<Name>"`.
- Profile `Name=` values must be single words; `.name` is what `-P` receives.
- A link must never be sent without a profile flag, or it lands in whichever instance Firefox picks.
- The Hyprland rules and the "last-focused profile" lookup key on the class `firefox-<id>`, which is
  now trustworthy on both backends.

## Not measured

- Other Firefox versions. Re-run the gate after a major bump.
- `--profile <path>` over XWayland (only `-P` was tested there).
- Whether `--new-instance` or `-no-remote` would be needed on any other Firefox build.
- Behaviour with more than two concurrent profiles, or with the real policy-installed add-ons loaded
  in each (the test profiles did show the add-on first-run pages, so policies do apply).
