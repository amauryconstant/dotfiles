# Firefox / NVIDIA EGL Wayland Deadlock

Investigation into Firefox wedging permanently under native Wayland on NVIDIA, why neither EGL
external platform library works, and which mitigations were tested and rejected.

## Summary

Firefox under native Wayland on NVIDIA **deadlocks** — the whole browser, not a crash, no
minidump, no coredump. Two symptoms that look unrelated are **one bug**:

| Platform library | Symptom |
|---|---|
| `libnvidia-egl-wayland2.so.1` (default, sorts first) | Fires on frame 1 — window never maps |
| `libnvidia-egl-wayland.so.1` (forced by our wrapper) | Fires later, when an extension popup creates a new EGL surface |

Both show the identical thread signature. The wrapper
(`private_dot_local/bin/executable_firefox`) trades "never opens" for "occasionally freezes".
No fix exists today: there is nothing newer to upgrade to, and every mitigation tested was
either ineffective or broke something else.

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

- `egl-wayland2` moves past 1.0.1 in Arch — retest wayland2 immediately; it is the supported path.
- Mozilla 2063934 or egl-wayland2 #47 get a fix — both are active as of 2026-08-25.
- Hyprland #5144 / #4521 fixed — re-enables the sharp XWayland recipe.
- If it becomes worth filing: the `WAYLAND_DEBUG` trace above is a strong reproducible report.

## Related

- `private_dot_local/bin/executable_firefox` — the wrapper, carries the full rationale in comments
- `private_dot_config/hypr/conf/environment.conf.tmpl` — sets `MOZ_ENABLE_WAYLAND`, `GDK_BACKEND`
