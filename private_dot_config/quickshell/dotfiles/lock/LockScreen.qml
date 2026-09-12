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
    property bool pendingSessionLock: false
    property bool authenticating: false
    // No lock before PAM is known good: a lock nobody can authenticate against
    // is a session nobody can re-enter.
    property bool pamConfigured: false
    property string failureMessage: ""
    // Which output carries the field. Page 12: every output is covered, the
    // prompt appears on ONE, "because two password fields is two places to type
    // a secret".
    property string promptScreenName: ""
    property bool strandedLock: false
    property bool strandedLockResolved: false
    property string pendingPassword: ""
    // Output name -> wallpaper path, from `awww query`. The lock draws the
    // wallpaper rather than a flat ground: a black rectangle is what the
    // FAILSAFE looks like, so a lock indistinguishable from a crashed one
    // teaches the user to read a real fault as normal.
    property var wallpapers: ({})

    readonly property bool locked: root.lockRequested || sessionLock.locked || sessionLock.secure
    // Both re-exported for the `lock status` IPC answer: a caller deciding
    // whether a restart is safe needs the compositor's view, not ours.
    readonly property bool secure: sessionLock.secure
    readonly property bool sessionLocked: sessionLock.locked

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

    // The focused output at lock time, re-elected when it goes away. Omarchy
    // draws a field on every screen and so never needs this; with one field,
    // unplugging the output that carries it would leave a locked session with
    // nowhere to type.
    function electPromptScreen(): void {
        const screens = root.realScreens();
        if (screens.length === 0)
            return;
        if (screens.some(s => s.name === root.promptScreenName))
            return;

        const focused = Hyprland.focusedMonitor?.name ?? "";
        root.promptScreenName = screens.some(s => s.name === focused) ? focused : screens[0].name;
    }

    // A lock taken while outputs are still settling lands on nothing, so the
    // request is queued behind a stabilize timer and retried until a real
    // screen exists.
    function queueSessionLock(): void {
        root.pendingSessionLock = true;
        stabilizeTimer.restart();
        pendingLockTimer.start();
    }

    function requestSessionLock(): void {
        if (!root.lockRequested || sessionLock.locked || sessionLock.secure)
            return;
        if (stabilizeTimer.running)
            return;

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
        root.electPromptScreen();
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
            if (sessionLock.locked) {
                root.pendingSessionLock = false;
                stabilizeTimer.stop();
                pendingLockTimer.stop();
                return;
            }
            if (root.lockRequested) {
                root.lockRequested = false;
                root.pendingSessionLock = false;
                stabilizeTimer.stop();
                pendingLockTimer.stop();
                root.resetAuthentication();
            }
        }
        onSecureStateChanged: {
            if (!sessionLock.secure)
                return;
            root.pendingSessionLock = false;
            stabilizeTimer.stop();
            pendingLockTimer.stop();
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
                promptVisible: surface.screen?.name === root.promptScreenName
                wallpaper: root.wallpaperFor(surface.screen?.name ?? "")

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
