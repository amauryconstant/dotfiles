pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick

// Surface §22 — the session lock. State, PAM and recovery live here;
// LockContent.qml draws what the user sees.
//
// 🚨 An ext-session-lock OUTLIVES its client. A locker that dies leaves the
// compositor holding the failsafe, which is opaque — the session is ugly, never
// exposed — and by default refuses a replacement client, which is what used to
// need a TTY to clear. hypr/conf/general sets misc:allow_session_lock_restore,
// so a fresh locker re-acquires the existing lock instead. That option plus
// quickshell.service (Restart=always) is this surface's whole crash story:
// design page 12 asks instead for a lock process supervised independently of
// the shell, and this tree answers the same danger the other way. See
// quickshell/CLAUDE.md for the ruling.
//
// Ported from Omarchy's shell/plugins/lock/Service.qml, minus the wallpaper,
// the fingerprint PAM, the DPMS blank/wake timers (hypridle owns DPMS here),
// the video-background poll and the preview window.
Item {
    id: root

    // What the user asked for, which leads sessionLock.locked by however long
    // the compositor takes to answer.
    property bool lockRequested: false
    // 🚨 Bumped wherever sessionLock.locked can change WITHOUT a notification, so the
    // two readonly bindings below re-read it. WlSessionLock::unlock() emits
    // lockStateChanged only `if (isLocked())` AFTER it has already unlocked
    // (_ai/quickshell/src/wayland/session_lock.cpp:183), i.e. never on a real
    // unlock. A binding over `sessionLock.locked` therefore kept its cached `true`
    // after the first unlock, `ipc call lock lock` answered "ok" without locking,
    // and so did hypridle's lock and lock-before-suspend. Do not "simplify" away.
    property int lockRev: 0
    property bool pendingSessionLock: false
    // When beginLock() ran, for the bound on waiting for the wallpaper decode.
    property real lockRequestedAt: 0
    property bool authenticating: false
    // No lock before PAM is known good: a lock nobody can authenticate against
    // is a session nobody can re-enter.
    property bool pamConfigured: false
    property string failureMessage: ""
    // Which output carries the field. Page 12: every output is covered, the
    // prompt appears on ONE, "because two password fields is two places to type
    // a secret". Elected at every lock (Config.lockPromptOutput, else the
    // focused output), then FOLLOWS the keyboard: see LockContent.surfaceActive.
    property string promptScreenName: ""
    property bool strandedLock: false
    property bool strandedLockResolved: false
    property string pendingPassword: ""
    // Output name -> wallpaper path, from `awww query`. The lock draws the
    // wallpaper rather than a flat ground: a black rectangle is what the
    // FAILSAFE looks like, so a lock indistinguishable from a crashed one
    // teaches the user to read a real fault as normal.
    property var wallpapers: ({})

    // `lockRev >= 0` is always true: it only makes the binding depend on lockRev.
    readonly property bool locked: root.lockRev >= 0 && (root.lockRequested || sessionLock.locked || sessionLock.secure)
    // Both re-exported for the `lock status` IPC answer: a caller deciding
    // whether a restart is safe needs the compositor's view, not ours.
    readonly property bool secure: sessionLock.secure
    readonly property bool sessionLocked: root.lockRev >= 0 && sessionLock.locked

    // `: eDP-1: 1920x1080, scale: 1, currently displaying: image: /path/to.png`
    // A line with no `image:` is an output showing a flat colour, and has no
    // path to take.
    function parseWallpapers(text: string): void {
        const marker = "currently displaying: image: ";
        const found = {};
        for (const line of (text ?? "").split("\n")) {
            const at = line.indexOf(marker);
            if (at < 0)
                continue;
            const head = line.replace(/^:\s*/, "");
            const name = head.slice(0, head.indexOf(":")).trim();
            if (name !== "")
                found[name] = line.slice(at + marker.length).trim();
        }
        root.wallpapers = found;
    }

    function wallpaperFor(screenName: string): string {
        const own = root.wallpapers[screenName ?? ""];
        if (own)
            return own;
        // A second output with no wallpaper of its own borrows one rather than
        // falling back to black, which reads as the failsafe.
        const any = Object.values(root.wallpapers);
        return any.length > 0 ? any[0] : "";
    }

    function realScreens(): var {
        return (Quickshell.screens ?? []).filter(s => s && s.name && s.width > 0 && s.height > 0);
    }

    // The EDID description in Config.lockPromptOutput, resolved to the output
    // name the screens are matched by. "" when unset or not plugged in.
    function preferredScreenName(): string {
        if (Config.lockPromptOutput === "")
            return "";
        // qmllint disable missing-property
        const monitor = Hyprland.monitors.values.find(m => m.description === Config.lockPromptOutput);
        // qmllint enable missing-property
        return monitor?.name ?? "";
    }

    // The preferred output, else the focused one, re-elected when it goes away.
    // Omarchy draws a field on every screen and so never needs this; with one
    // field, unplugging the output that carries it would leave a locked session
    // with nowhere to type. beginLock() clears the name first, so every lock
    // elects afresh -- a name left over from shell start is not a choice (that
    // pinned the field to whichever output happened to be focused at login).
    function electPromptScreen(): void {
        const screens = root.realScreens();
        if (screens.length === 0)
            return;
        if (screens.some(s => s.name === root.promptScreenName))
            return;

        const preferred = root.preferredScreenName();
        const focused = Hyprland.focusedMonitor?.name ?? "";
        if (screens.some(s => s.name === preferred))
            root.promptScreenName = preferred;
        else if (screens.some(s => s.name === focused))
            root.promptScreenName = focused;
        else
            root.promptScreenName = screens[0].name;
    }

    // 🚨 Hyprland gives a session lock's keyboard focus to the lock surface of
    // the output UNDER THE POINTER (InputManager.cpp, the isSessionLocked branch
    // of mouseMoveUnified), not to the one the field is on. With two outputs, a
    // pointer on the other one types into a surface with no field. So the
    // pointer is moved to the elected output before the lock maps. The target is
    // LOGICAL: HyprlandMonitor.width/height are physical, hence the scale.
    function warpPointerToPrompt(): void {
        if (root.realScreens().length < 2 || warpProc.running)
            return;
        // qmllint disable missing-property
        const monitor = Hyprland.monitors.values.find(m => m.name === root.promptScreenName);
        // qmllint enable missing-property
        if (!monitor)
            return;

        const x = Math.round(monitor.x + monitor.width / monitor.scale / 2);
        const y = Math.round(monitor.y + monitor.height / monitor.scale / 2);
        warpProc.command = ["hyprctl", "dispatch", `hl.dsp.cursor.move({ x = ${x}, y = ${y} })`];
        warpProc.running = true;
    }

    // A lock taken while outputs are still settling lands on nothing, so the
    // request is queued behind a stabilize timer and retried until a real
    // screen exists.
    function queueSessionLock(): void {
        root.pendingSessionLock = true;
        stabilizeTimer.restart();
        pendingLockTimer.start();
    }

    // False while a wallpaper decode started by beginLock() is still running.
    function wallpapersWarm(): bool {
        for (let i = 0; i < wallpaperWarm.count; i++) {
            // qmllint disable missing-property
            if (wallpaperWarm.itemAt(i)?.status === Image.Loading)
                return false;
            // qmllint enable missing-property
        }
        return true;
    }

    function requestSessionLock(): void {
        if (!root.lockRequested || sessionLock.locked || sessionLock.secure)
            return;
        if (stabilizeTimer.running)
            return;
        // 🚨 The surfaces draw a scrim until their wallpaper has decoded, and a
        // 17 MB PNG takes longer than the 500 ms settle window, so wait for the
        // decode beginLock() started: the lock then appears with its wallpaper
        // instead of black. BOUNDED at 1 s from the request, because a lock that
        // waits on a decode that never finishes is a screen that stays unlocked.
        if (!root.wallpapersWarm() && Date.now() - root.lockRequestedAt < 1000) {
            pendingLockTimer.start();
            return;
        }

        if (root.realScreens().length === 0) {
            root.pendingSessionLock = true;
            pendingLockTimer.start();
            return;
        }

        root.pendingSessionLock = false;
        pendingLockTimer.stop();
        root.electPromptScreen();
        sessionLock.locked = true;
    }

    function beginLock(): bool {
        if (!root.pamConfigured)
            return false;

        root.resetAuthentication();
        root.lockRequestedAt = Date.now();
        root.promptScreenName = "";
        root.electPromptScreen();
        root.warpPointerToPrompt();
        // Re-read at every lock: the wallpaper timer cycles it every 30 minutes.
        if (!wallpaperProc.running)
            wallpaperProc.running = true;
        root.lockRequested = true;
        root.queueSessionLock();
        return true;
    }

    function finishUnlock(): void {
        if (!root.locked && !root.lockRequested)
            return;

        root.lockRequested = false;
        root.pendingSessionLock = false;
        stabilizeTimer.stop();
        pendingLockTimer.stop();
        root.resetAuthentication();
        // There is no unlock() invokable — the property IS the control.
        sessionLock.locked = false;
        // Synchronous, so the getter already reads false; see lockRev.
        root.lockRev += 1;
    }

    // The compositor dropped our lock (a forced unlock, or another locker took
    // over) without finishUnlock() running: forget that we asked for one.
    function abandonLock(): void {
        root.lockRequested = false;
        root.pendingSessionLock = false;
        stabilizeTimer.stop();
        pendingLockTimer.stop();
        root.resetAuthentication();
    }

    function bumpLockRev(): void {
        root.lockRev += 1;
    }

    function resetAuthentication(): void {
        root.authenticating = false;
        root.pendingPassword = "";
        root.failureMessage = "";
        if (pam.active)
            pam.abort();
    }

    function submit(value: string): void {
        const password = value ?? "";
        if (!root.lockRequested || root.authenticating || password.length === 0)
            return;

        root.pendingPassword = password;
        root.failureMessage = "";
        root.authenticating = true;

        if (!pam.start()) {
            root.handleFailure();
            return;
        }
        // start() only opens the conversation; the prompt arrives after it.
        Qt.callLater(root.respondToPrompt);
    }

    function respondToPrompt(): void {
        if (!root.authenticating || !pam.active || !pam.responseRequired)
            return;
        pam.respond(root.pendingPassword);
    }

    // 🚨 No attempt counter. Design page 12: a failure "does not count down
    // publicly" — a number on a lock screen tells whoever is watching how much
    // patience is left. PAM's own text when it has some, a fixed string when
    // not; never a paraphrase of a message the system wrote.
    function handleFailure(): void {
        if (!root.lockRequested)
            return;

        root.authenticating = false;
        root.pendingPassword = "";
        root.failureMessage = pam.messageIsError && pam.message !== "" ? pam.message : qsTr("Authentication failed");
    }

    // ext-session-lock outlives its client and a restarted shell carries no
    // lock over, so a session locked this early is an orphan behind the
    // failsafe. Outputs are often still absent here, hence the retry budget.
    //
    // 🚨 The probe is session-lock-stranded, NOT session-locked. The latter
    // answers "is the compositor locked", which is also true while hyprlock is
    // running -- and with misc:allow_session_lock_restore a second client is
    // accepted rather than refused, so recovering on that answer takes the
    // screen out from under whoever is typing into the live locker. Measured
    // 2026-09-12, on exactly that: a restart during hypridle's hyprlock.
    function checkStranded(): void {
        if (root.strandedLockResolved || strandedProc.running)
            return;

        // A lock THIS shell took is nobody's orphan.
        if (root.locked || root.lockRequested) {
            root.strandedLockResolved = true;
            return;
        }

        strandedProc.running = true;
    }

    function recoverStranded(): void {
        if (!root.strandedLock || root.locked || !root.pamConfigured)
            return;

        root.strandedLock = false;
        root.beginLock();
    }

    Component.onCompleted: {
        // Elected up front as well as at beginLock, so `lock status` names a
        // real output before anything has locked.
        root.electPromptScreen();
        // Before checkStranded: a recovery locks immediately, and a lock that
        // arrives before its wallpaper does flashes the failsafe's own colour.
        wallpaperProc.running = true;
        root.checkStranded();
    }

    WlSessionLock {
        id: sessionLock

        locked: false

        onLockStateChanged: {
            root.lockRev += 1;
            if (sessionLock.locked) {
                root.pendingSessionLock = false;
                stabilizeTimer.stop();
                pendingLockTimer.stop();
                return;
            }
            if (root.lockRequested)
                root.abandonLock();
        }
        // The only signal that follows a real unlock (lockStateChanged does not,
        // see lockRev). It is connected BEFORE WlSessionLock::unlock(), so the
        // getter can still read true here: bump now and once more after the slot
        // chain has run.
        onSecureStateChanged: {
            root.lockRev += 1;
            Qt.callLater(root.bumpLockRev);
            if (sessionLock.secure) {
                root.pendingSessionLock = false;
                stabilizeTimer.stop();
                pendingLockTimer.stop();
                return;
            }
            if (root.lockRequested)
                root.abandonLock();
        }

        // One surface per screen, instantiated by the engine. That is what
        // satisfies page 12's hotplug rule — a new output cannot display
        // anything until its lock surface exists.
        WlSessionLockSurface {
            id: surface

            // What shows before the wallpaper image has decoded, and wherever
            // there is no wallpaper to draw. Theme.scrim rather than a ground
            // token: groundBase measures 0.71-0.96 luminance in the four light
            // colorsets, and a pale flash on a lock surface is a leak-shaped
            // frame.
            color: Theme.scrim

            LockContent {
                anchors.fill: parent
                failureMessage: root.failureMessage
                inputEnabled: root.lockRequested && !root.authenticating
                // qmllint disable missing-property redundant-optional-chaining
                promptVisible: surface.screen?.name === root.promptScreenName
                wallpaper: root.wallpaperFor(surface.screen?.name ?? "")

                // The field goes where the keys go: whichever surface the
                // compositor has keyboard-focused takes the prompt.
                onSurfaceActiveChanged: {
                    if (surfaceActive && root.lockRequested && surface.screen?.name)
                        root.promptScreenName = surface.screen.name;
                }
                // qmllint enable missing-property redundant-optional-chaining

                onSubmitted: password => root.submit(password)
            }
        }
    }

    PamContext {
        id: pam

        // Shipped by the hyprlock package (`auth include login`), so it is
        // package-managed and never ours to maintain — no root write, no
        // installer script. `user` is left unset: an empty one falls back to
        // getpwuid_r(getuid()) in qml.cpp.
        config: "hyprlock"

        onCompleted: result => {
            root.authenticating = false;
            root.pendingPassword = "";
            if (!root.lockRequested)
                return;
            if (result === PamResult.Success)
                root.finishUnlock();
            else
                root.handleFailure();
        }
        onError: root.handleFailure()
        // The prompt can arrive before or after start() returns, so both edges
        // feed the same responder and it no-ops when there is nothing to answer.
        onPamMessage: root.respondToPrompt()
        onResponseRequiredChanged: root.respondToPrompt()
    }

    // ⚠️ An answer from before a PAM change may be stale — the failsafe can be
    // cleared from a TTY — so re-ask rather than act on what was cached.
    FileView {
        path: "/etc/pam.d/hyprlock"
        printErrors: false
        watchChanges: true

        onFileChanged: this.reload()
        onLoadFailed: root.pamConfigured = false
        onLoaded: root.pamConfigured = true
    }

    onPamConfiguredChanged: {
        if (!root.pamConfigured)
            return;
        root.strandedLock = false;
        root.strandedLockResolved = false;
        strandedRetryTimer.rearm();
        root.checkStranded();
    }

    Process {
        id: wallpaperProc

        command: ["awww", "query"]

        stdout: StdioCollector {
            onStreamFinished: root.parseWallpapers(this.text)
        }
    }

    Process {
        id: warpProc
    }

    // 🚨 The wallpaper is decoded from beginLock(), not when the surfaces appear:
    // the surfaces come up 500 ms later (stabilizeTimer) and each one used to
    // start its own decode of the file, through Qt's single image-reader thread,
    // showing the dark scrim until it finished (measured 2026-10-19: Ready
    // 250-450 ms after the surfaces for a 17 MB PNG, in a 1526x830 sandbox).
    // These hidden Images fill Qt's pixmap cache, which is reference-counted, so
    // the decoded pixmaps live exactly as long as the lock does. The surfaces'
    // own Image (LockContent) hits that cache ONLY with the same url, the same
    // sourceSize (an output's logical size is the lock surface's size) AND the
    // same fillMode: PreserveAspectCrop is part of the key, and a warm Image
    // without it never hit (measured 2026-10-19 by probing each property).
    Repeater {
        id: wallpaperWarm

        model: root.lockRequested ? root.realScreens() : []

        Image {
            id: warm

            required property var modelData

            asynchronous: true
            cache: true
            // Must match LockContent's Image, see above.
            fillMode: Image.PreserveAspectCrop
            source: root.wallpaperFor(warm.modelData.name) === "" ? "" : `file://${root.wallpaperFor(warm.modelData.name)}`
            sourceSize.height: warm.modelData.height
            sourceSize.width: warm.modelData.width
            visible: false

            // A decode that finishes after the settle window is what the lock is
            // waiting for (requestSessionLock).
            onStatusChanged: root.requestSessionLock()
        }
    }

    Process {
        id: strandedProc

        command: [`${Config.scriptsDir}/desktop/session-lock-stranded`]

        // 🚨 Exit 2 is "undetermined", a real third answer: Hyprland stops at
        // the first blocking reason, so a monitor with no workspace yet reports
        // WORKSPACE and the lock is never reached. Resolving on it is how a
        // real orphan gets missed. 1 covers BOTH "unlocked" and "a live locker
        // owns it", which is the whole point of asking this script instead.
        //
        // Process.exited carries a second QProcess::ExitStatus argument whose
        // type nothing declares to the linter. Upstream gap, unavoidable when
        // reading an exit code -- see .claude/rules/quickshell-qml.md.
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 2)
                return;

            root.strandedLockResolved = true;
            // A lock taken while this was in flight is this shell's own.
            root.strandedLock = exitCode === 0 && !root.locked && !root.lockRequested;
            root.recoverStranded();
        }
        // qmllint enable signal-handler-parameters
    }

    Timer {
        id: stabilizeTimer

        interval: 500

        onTriggered: root.requestSessionLock()
    }

    Timer {
        id: pendingLockTimer

        interval: 100
        repeat: true

        onTriggered: root.requestSessionLock()
    }

    Timer {
        id: strandedRetryTimer

        readonly property int budget: 20
        property int remaining: 20

        function rearm(): void {
            if (!root.strandedLockResolved)
                strandedRetryTimer.remaining = strandedRetryTimer.budget;
        }

        interval: 500
        repeat: true
        running: !root.strandedLockResolved && strandedRetryTimer.remaining > 0

        onTriggered: {
            strandedRetryTimer.remaining -= 1;
            root.checkStranded();
        }
    }

    Connections {
        function onScreensChanged(): void {
            root.electPromptScreen();
            root.requestSessionLock();
            // A monitor still coming up has no workspace, so it cannot answer
            // the stranded question yet.
            strandedRetryTimer.rearm();
            root.checkStranded();
        }

        target: Quickshell
    }
}
