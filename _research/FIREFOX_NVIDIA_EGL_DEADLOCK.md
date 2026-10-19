# NVIDIA EGL Wayland Deadlock (Firefox, Quickshell lock)

Investigation into Firefox wedging permanently under native Wayland on NVIDIA, why neither EGL
external platform library works, and which mitigations were tested and rejected. The same
unbounded wait later turned out to be what froze the Quickshell session lock on the desktop
(see "Second victim"); the filename stays because other files link to it.

## Summary

Firefox under native Wayland on NVIDIA **deadlocks** — the whole browser, not a crash, no
minidump, no coredump. Two symptoms that look unrelated are **one bug**:

| Platform library | Symptom |
|---|---|
| `libnvidia-egl-wayland2.so.1` (default, sorts first) | Fires on frame 1 — window never maps |
| `libnvidia-egl-wayland.so.1` (forced by our wrapper) | Fires later, when an extension popup creates a new EGL surface |

Both show the identical thread signature.

**Resolved 2026-10-14 with a local patch to egl-wayland2** — see "Root cause and fix" below. The
sections after it are the original investigation (written against firefox 154 / egl-wayland2
1.0.1) and are kept as evidence, not as current state.

## Root cause and fix (2026-10-14)

Retested on firefox 157.0.1, nvidia 615.78.08, egl-wayland 1.1.24, egl-wayland2 1.0.2 **and
upstream master (1.0.3, `ce0eb71`)**: all three configurations still wedged (wayland2 never
maps; legacy freezes on the Bitwarden popup). A `eu-stack` of the wedged wayland2 process
(debug build, so frames are named) finally showed where the Renderer blocks:

```
Renderer   ppoll -> wl_display_dispatch_queue -> WaitForPreviousFrames
           -> eplWlSwapBuffers -> HookSwapBuffersWithDamage
main       pthread_cond_wait (waits for the Renderer) <- gtk draw
```

`WAYLAND_DEBUG` trace of the same run: the EGL surface (`wl_surface#69`) is a **desync
subsurface** of the toplevel (`#76`). The swap path is FIFO + `wp_presentation`; every swap
requests `wp_presentation.feedback` and the next swap's `WaitForPreviousFrames` waits for it.
The compositor does not answer for a subsurface whose parent toplevel is not mapped, and the
parent is mapped by the GTK main thread — which is blocked waiting for this very Renderer.
The GTK CSD shm buffer is created and never attached, which matches the old trace.

The first guess was a **synchronized** subsurface; the trace refuted it (`set_desync`).

**Proof**: making every swap behave as swap interval 0 (no wait) mapped the window and let
Bitwarden open repeatedly. That removes the throttle, so the shipped patch bounds the wait
instead.

**Fix**: `.patches/egl-wayland2-bounded-frame-wait.patch` — `WaitForPreviousFrames` uses
`wl_display_dispatch_queue_timeout` (100 ms) and, on timeout, abandons the outstanding frame
callback / swap sync / presentation feedback exactly as the interval-0 path already does. Built
from a pinned upstream commit into `~/.local/lib/egl-wayland2-patched` by
`.chezmoiscripts/run_after_build_egl_wayland2_patched.sh.tmpl`; the Firefox wrapper
points its EGL platform config at it. Every other client keeps the packaged library.
`__NV_DISABLE_EXPLICIT_SYNC` is gone from the wrapper — it was unproven and the patched run
passed without it.

**Fallback** if the build is absent: XWayland (no wedge, soft text on DP-1 because Hyprland
stretches the 1x X window). Sharp XWayland via `xwayland:force_zero_scaling` was retested on
Hyprland 0.56.2 and is **still broken**: the window overflows its tile and the right part is
not clickable (input region stays at logical size).

**Verified**: Bitwarden popup, window mapping, normal use on DP-1. **Not verified**: tearing /
frame pacing under video (100 ms bound only matters when feedback never arrives), HDMI-A-1,
whether the patch is acceptable upstream.

**Patch limits** (for the upstream report): the 100 ms is silence per dispatch, not a total cap —
a compositor that answers late but steadily is never cut off. `wl_display_dispatch_queue_timeout`
needs libwayland >= 1.23, which upstream would have to guard; the build script checks it.

**Upstream report not yet filed.** NVIDIA/egl-wayland2: evidence above, expected behaviour
(a swap must not block indefinitely on feedback for a surface the compositor may never present),
the patch. Related: Mozilla 2063934, egl-wayland2 #47 (different symptom).

## Second victim: the Quickshell session lock (2026-10-19)

**Symptom** (2026-10-14, desktop: DP-1 4K@144 scale 1.25 + HDMI-A-1): the in-shell lock came up,
took keys for a few seconds, then Quickshell went silent while Hyprland stayed alive. A LOCKDBG
journal from that day shows the shape: lock up at 17:35:18, 78 key events in 7 s including a held
Backspace, last 3 s heartbeat at 17:35:24.96, nothing afterwards. It was first read as a focus
problem; it is not. 670f0b2 pulled the desktop back to hyprlock.

**Reproduced** in the `desk` sandbox (`DESK_LOCK=1`, two nested outputs, lock via
`quickshell -c dotfiles ipc call lock lock`): the lock appeared and the shell wedged at once, no
typing needed. `quickshell ipc call lock status` is served on the main thread, so no answer means
wedged. Run under gdb (SIGINT then `thread apply all bt`), with the packaged egl-wayland2 1.0.2:

```
QSGRenderThread  ppoll -> wl_display_dispatch_queue -> libnvidia-egl-wayland2
                 -> libEGL_nvidia -> QWaylandGLContext::swapBuffers -> QRhi::endFrame
main thread      QWaitCondition::wait (Qt Quick, from QWindow::event / expose)
                 <- QWaylandWindow::sendExposeEvent <- updateExposure
```

Same wait as Firefox's (`WaitForPreviousFrames`, no timeout), with the main thread blocked on the
render thread exactly as GTK's was. `/proc/<pid>/task/*/wchan` agrees: main `futex_do_wait`, render
`poll_schedule_timeout`.

**Fix**: run the shell on the patched build. With `__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS` pointing at
a platform dir whose `09_nvidia_wayland2.json` names `~/.local/lib/egl-wayland2-patched`, the
sandbox locked, typed and held Backspace for 6, then 10, rounds with no wedge. The platform dir is
now built by `desktop/egl-wayland2-patched`, shared with the Firefox wrapper;
`quickshell.service` starts through it, and `Config.detach` strips the variable so apps opened
from the launcher keep the packaged library.

**Caveats**
- The patched build is upstream **1.0.3 plus the patch**; the packaged library under test was
  1.0.2. The Firefox work showed unpatched 1.0.3 still wedges, but nobody ran unpatched 1.0.3 under
  Quickshell, so the patch itself is inferred, not isolated, for this client.
- The shell as a whole now runs the bounded wait: the bar, OSD and launcher too. It only changes
  behaviour when the compositor stops sending frame events, but verify idle CPU and animation
  smoothness over a few days.
- Sandbox scale was 1, not the desktop's 1.25 (the nested output would not take a scale), and the
  outputs were nested windows, not real connectors.
- A missing patched build means the shell runs the packaged library and the freeze can return;
  nothing alerts except the build script's warning. No runtime guard was added on purpose.
- The laptop renders the shell through Mesa on its iGPU, so the variable is inert there, which is
  consistent with the lock never freezing on it.

## Original investigation (superseded)

The sections below predate the fix.

## The deadlock

Stack-sampled a wedged process with `eu-stack`. Zero CPU advance over 5s, byte-identical stacks
seconds apart — a hard deadlock, not slowness:

```
main thread   gtk_main_do_event -> draw signal -> libxul
              -> mozilla::detail::ConditionVariableImpl::wait_for   (waits for the renderer)
Renderer      libxul -> libEGL_nvidia.so.610.57.04
              -> libnvidia-egl-wayland.so.1.1.21
              -> wl_display_dispatch_queue -> ppoll                 (waits for a Wayland event)
```

The renderer blocks inside NVIDIA's EGL platform waiting on a Wayland event; the main thread —
the only thread that can drive that surface — is blocked waiting for the renderer, from inside
a GTK draw handler. The cycle never breaks.

Same shape as Mozilla bug 1734368 (Mesa, fixed in Firefox 95 by making `FlushRendering` async).
Ours is a residual instance on the NVIDIA path.

## Ruled out — with evidence

| Hypothesis | Test | Result |
|---|---|---|
| GPU fault / Xid | kernel log | Clean. No Xid, no reset |
| Compositor protocol error | Hyprland log | No error; compositor thinks all is well |
| libwayland reader deadlock (events sent, unread) | `ss -x` on all 64 Firefox sockets | **Zero** unread bytes. Nothing queued |
| An EGL error precedes the hang | `EGL_KHR_debug` via gl-debug-preload, INFO+WARN+ERROR+CRITICAL | **Zero messages.** Clean block, not an error path |
| egl-wayland2 issue #47 (`EGL_BAD_SURFACE` 0x3009) | as above | Not our failure |
| Explicit sync (`wp_linux_drm_syncobj`) | `__NV_DISABLE_EXPLICIT_SYNC=1` | Verified effective (91 `set_acquire_point` / 91 `set_release_point` / 1 `get_surface` -> 0), dmabuf + HW rendering retained. **Wedge unchanged** |
| Fractional scaling | `widget.wayland.fractional-scale.enabled=false` | Verified effective (`get_fractional_scale` never called). **Wedge unchanged.** `wp_viewport.set_destination` still occurs |
| wayland2 broken system-wide | ghostty under wayland2-only config | Works — GL 4.6 via `libnvidia-egl-wayland2.so.1.0.1`. **Firefox-specific** |
| `widget.dmabuf.enabled=false` | launch | No window |
| GBM-only EGL config | launch | Window maps, but no GPU acceleration |
| `gfx.webrender.compositor=false`, `widget.wayland.use-move-to-rect=false` | A/B with control arm | Placebos — control arm passed too |
| `gfx.webrender.software=true` | launch | Works, but loses hardware acceleration |

## Where wayland2 stops

`WAYLAND_DEBUG` trace of the frame-1 failure:

- Toplevel `wl_surface#83` acks its configure, then **never receives a single `wl_surface.attach`**.
  Per xdg-shell that is exactly "acked, never presented" -> no window.
- 3 dmabuf `wl_buffer`s created; exactly **one** attached (to the subsurface). Last one never attached.
- A GTK CSD shm buffer is created and never attached — the main thread died mid-draw.
- `MOZ_LOG=WidgetWayland:5` last line ever: `WaylandSurface::SetViewPortDestLocked()`, after the
  Renderer resized the EGL window twice.

Likely trigger — the upstream README for egl-wayland2 states the client contract:

> An application **MUST NOT** send a `wl_surface.commit` request for a surface concurrently with
> an `eglSwapBuffers` call.

The trace shows the **main thread** issuing five `wl_surface#78.commit()` calls (`{Default Queue}`)
on the EGL-backed surface, interleaved with the Renderer's commits (`{EGLSurface(78)}`). Cause and
documented prohibition line up. Confidence: medium-high — not proven, since we could not get a
stack showing where inside `eglSwapBuffers` it blocks.

## Monitor correlation (unconfirmed)

Freezes observed almost exclusively on **DP-1 (3840x2160, scale 1.25)**, not reproduced on
**HDMI-A-1 (2560x1440, scale 1.0, rotated)**. Possible selection bias — Firefox mostly lives on
DP-1. Disabling Firefox's fractional-scale path did not help, but `wp_viewport` stays in use
either way, so the observation is not contradicted.

## Options evaluated

| Option | Verdict |
|---|---|
| Switch to wayland2 | **Not viable.** Deterministic frame-1 wedge; nothing newer to upgrade to |
| `__NV_DISABLE_EXPLICIT_SYNC=1` | Kept as zero-cost measure; **unproven**, likely ineffective |
| XWayland + `force_zero_scaling` + `devPixelsPerPx=1.25` | **Rejected.** Sharp and deadlock-free, but clicks land wrong — error grows with distance from monitor origin (Hyprland #5144 / #4521, open) |
| XWayland without `force_zero_scaling` | Viable but text is upscaled from logical to native — softer |
| Integer scale on DP-1 | Untested. Would remove fractional path and fix XWayland clicks, but resizes the whole desktop |
| Build `egl-wayland2` from master | **Untested — best remaining lead.** Issues #41, #46 closed after 1.0.1 |

No Firefox pref selects the EGL platform: Firefox calls
`eglGetPlatformDisplay(EGL_PLATFORM_WAYLAND_KHR, ...)` and libEGL's config-dir scan decides.
`__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS` is the only lever — which is what the wrapper uses.

## Reproducing / instrumenting

**Deterministic reproducer** (wayland2 wedges every time, unlike the intermittent legacy path):
build a config dir containing symlinks to only `09_nvidia_wayland2.json` plus the gbm/xcb/xlib
ones, point `__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS` at it, and launch
`/usr/lib/firefox/firefox --no-remote --profile <throwaway>` (call the real binary — the wrapper
overrides the platform choice). Never `pkill firefox`; kill test instances by exact PID.

**Stack sampling** needs ptrace relaxed (`sudo sysctl -w kernel.yama.ptrace_scope=0`, revert to
`1` afterwards), then `DEBUGINFOD_URLS= eu-stack -p <pid>`. Healthy vs wedged is easy to tell
from `/proc/<pid>/task/*/wchan` alone: healthy = main in `poll`, Renderer in `futex`; wedged =
main in `futex`, Renderer in `poll_schedule_timeout` (ppoll).

**EGL error reporting**: `gl-debug-preload` (git.freedesktop.org/kbrenneman), meson build,
`LD_PRELOAD=egl_debug_preload.so`. Note `gl_debug_preload.so` cannot hook Firefox — it `dlopen`s
libEGL at runtime.

## Environment

`firefox 154.0-1` · `firefox-esr 153.1.0-1` · `egl-wayland 4:1.1.21-1` · `egl-wayland2 1.0.1-1`
· `nvidia-utils 610.57.04-1` · `nvidia-open 610.57.04-8` · `wayland 1.26.0-1` ·
`gtk3 1:3.24.52-1` · `hyprland 0.56.2-1`

`egl-wayland2 1.0.1` is simultaneously the newest in Arch `extra` and the newest upstream
release. Its Arch package description ("EGLStream-based Wayland external platform") is **wrong** —
egl-wayland2 is dma-buf based and EGLStream-free.

## Upstream status

| Reference | State |
|---|---|
| [Mozilla 1734368](https://bugzilla.mozilla.org/show_bug.cgi?id=1734368) — deadlock at `WaitForSyncNotify()` / `get_back_bo()` | Fixed in Firefox 95. Same shape as ours |
| [Mozilla 1908825](https://bugzilla.mozilla.org/show_bug.cgi?id=1908825) — explicit sync on NVIDIA | Fixed in egl-wayland 1.1.15+ |
| [Mozilla 2063934](https://bugzilla.mozilla.org/show_bug.cgi?id=2063934) — startup crash in `libnvidia-egl-wayland2.so.1` | **NEW**, triaged to gfx 2026-08-24 |
| [egl-wayland2 #47](https://github.com/NVIDIA/egl-wayland2/issues/47) — Firefox 151, `EGL_BAD_SURFACE` | Open |
| egl-wayland2 #41, #46 | Closed **after** 1.0.1 — not in Arch |
| [Hyprland #5144](https://github.com/hyprwm/Hyprland/issues/5144), [#4521](https://github.com/hyprwm/Hyprland/issues/4521) — XWayland click offset with `force_zero_scaling` | Open |
| [fdo 106753](https://wayland-bugs.freedesktop.narkive.com/zvKT7IWP/bug-106753-firefox-wayland-multithread-deadlock-at-eglswapbuffers-wl-display-dispatch-queue) — Firefox multithread deadlock at `eglSwapBuffers()` | Historical precedent, exact shape |

## When to Revisit

- **Drop the patch** once an egl-wayland2 release bounds or removes that wait: delete
  `.patches/`, the build script, `desktop/egl-wayland2-patched` and the patched branch of the
  Firefox wrapper, revert `quickshell.service`'s `ExecStart`, the `env -u` prefix of
  `Config.detach` and the helper launch in `.claude/skills/desk/scripts/desk`, then
  `rm -rf ~/.local/lib/egl-wayland2-patched`. Test with `FIREFOX_BACKEND=` unset against the
  packaged library and the Bitwarden popup, **and** a `DESK_LOCK=1` lock-and-type run on two outputs.
- Bump `EGL_WAYLAND2_COMMIT` in the build script only after re-running both tests.

- `egl-wayland2` moves past 1.0.2 in Arch — retest wayland2 immediately; it is the supported path.
- Mozilla 2063934 or egl-wayland2 #47 get a fix — both are active as of 2026-08-25.
- Hyprland #5144 / #4521 fixed — re-enables the sharp XWayland recipe.
- If it becomes worth filing: the `WAYLAND_DEBUG` trace above is a strong reproducible report.

## Related

- `private_dot_local/bin/executable_firefox` — the wrapper, carries the full rationale in comments
- `private_dot_local/lib/scripts/desktop/executable_egl-wayland2-patched` — builds the EGL platform
  dir for Firefox and `quickshell.service`
- `private_dot_config/systemd/user/quickshell.service`, `Config.detach` in
  `private_dot_config/quickshell/dotfiles/Config.qml.tmpl` — the shell side
- `.patches/egl-wayland2-bounded-frame-wait.patch` — the fix
- `.chezmoiscripts/run_after_build_egl_wayland2_patched.sh.tmpl` — builds it (pinned commit,
  stamp-guarded, retried until it succeeds)
- `private_dot_config/hypr/conf/environment.conf.tmpl` — sets `MOZ_ENABLE_WAYLAND`, `GDK_BACKEND`
