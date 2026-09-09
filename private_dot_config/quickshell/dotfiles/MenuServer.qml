pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

// The dmenu substrate. Twenty-two scripts in this repo ask the user to pick
// from a list, and until now every one of them shelled out to `wofi --dmenu`.
// This is the same contract served by the shell instead.
//
// 🚨 A dmenu call is REQUEST/RESPONSE AND BLOCKING: the script must not return
// until the user has chosen. `quickshell ipc call` cannot do that -- a handler
// returns immediately, and `ipc call` exits 0 even when the target does not
// exist, so a caller could not even tell. A socket can: one connection is one
// invocation, and the caller blocks on the read until this file answers.
//
// Protocol, one line each way:
//   in   {"prompt": "Main Menu", "items": ["a", "b"]}
//   out  the chosen item, or nothing at all when cancelled
// The connection closes either way, which is what releases the caller.
//
// The caller is `desktop/quickshell-menu`, which falls back to wofi when this
// socket is absent -- see that script for why the fallback is load-bearing.
Singleton {
    id: root

    property string prompt: ""
    property list<var> items: []
    // One picker at a time. A second request while one is open is refused
    // immediately rather than queued: a menu that appears minutes later,
    // attached to a script that has moved on, is worse than a refusal.
    property bool busy: false
    property var activeSocket: null

    // The picker opens on this, and closes on `aborted` -- which fires when the
    // CALLER goes away (killed script, closed terminal). Without it the surface
    // would sit there waiting to answer a socket nobody is reading.
    signal requested
    signal aborted

    // Writes the answer and releases the caller. An empty string is a
    // cancellation: the caller sees a closed connection with no output and
    // exits 1, exactly as `wofi --dmenu` does on Esc.
    function respond(text: string): void {
        const sock = root.activeSocket;
        root.activeSocket = null;
        root.busy = false;
        root.prompt = "";
        root.items = [];
        if (!sock)
            return;
        if (text !== "") {
            sock.write(`${text}\n`);
            sock.flush();
        }
        // Safe immediately after a write: QLocalSocket::disconnectFromServer
        // enters ClosingState and drains anything still pending first.
        sock.connected = false;
    }

    SocketServer {
        active: true
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-menu.sock`

        handler: Socket {
            id: conn

            parser: SplitParser {
                onRead: message => {
                    let request = null;
                    try {
                        request = JSON.parse(message);
                    } catch (e) {
                        conn.connected = false;
                        return;
                    }
                    if (root.busy) {
                        conn.connected = false;
                        return;
                    }
                    root.activeSocket = conn;
                    root.busy = true;
                    root.prompt = request.prompt ?? "";
                    root.items = (request.items ?? []).filter(i => typeof i === "string");
                    root.requested();
                }
            }

            onConnectedChanged: {
                if (conn.connected || root.activeSocket !== conn)
                    return;
                // The caller vanished mid-choice.
                root.activeSocket = null;
                root.busy = false;
                root.aborted();
            }
        }
    }
}
