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
// Two optional request fields carry design page 10's navigation model without
// moving the TREE into the shell, which stays in the menu-* scripts:
//   "breadcrumb": "Setup"     -- drawn before the prompt, so a submenu says
//                                where it is
//   "back": "󰁍 Back"          -- what to answer on Left or Backspace with an
//                                empty query. It is a PAYLOAD, so the calling
//                                script dispatches it through the same `case`
//                                arm its Back row already uses, and a caller
//                                that omits it behaves exactly as before.
//
// An item may also be an OBJECT, which is how a caller reaches the row contract
// PickerSurface already has instead of packing glyph, state and payload into
// one string:
//   {"title": "Rose Pine Dawn", "glyph": "", "badge": "current",
//    "iconSource": "file:///home/…/themes/rose-pine-dawn/icon.png",
//    "payload": "rose-pine-dawn"}
//   {"header": true, "title": "LIGHT"}
// `payload` is what the caller is answered with -- so a slug travels without
// being shown to the user or joining the fuzzy-match haystack -- and defaults to
// the title.
//
// 🚨 A plain string stays a plain string: it normalises to
// `{title: s, payload: s}`, so all sixteen show_menu() callers, the empty-string
// element menu-install's free-text prompt relies on, and the `case` statements
// every one of them matches with are untouched.
//
// The caller is `desktop/quickshell-menu`, which falls back to wofi when this
// socket is absent -- see that script for why the fallback is load-bearing.
Singleton {
    id: root

    property string prompt: ""
    property list<var> items: []
    // Where the caller sits in its own tree, and what to answer when the user
    // goes back. Both optional: a caller that sends neither gets exactly the
    // surface it got before. `back` is a payload, so the calling script's own
    // `case` handles it with no new vocabulary.
    property string breadcrumb: ""
    property string back: ""
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

    // One row out of whatever the caller sent. A string is the whole row; an
    // object supplies the row contract directly. Anything else is dropped, as
    // it always was.
    function normalise(item: var): var {
        if (typeof item === "string")
            return {
                title: item,
                payload: item
            };
        if (!item || typeof item.title !== "string")
            return null;
        return {
            title: item.title,
            subtitle: item.subtitle ?? "",
            glyph: item.glyph ?? "",
            // A file:// URL, or anything else QtQuick.Image takes. It wins over
            // the glyph, which stays the fallback for a missing file and for
            // the Wofi path, where an image cannot be drawn at all.
            iconSource: item.iconSource ?? "",
            badge: item.badge ?? "",
            glyphColor: item.glyphColor ?? "",
            glyphBackground: item.glyphBackground ?? "",
            payload: item.payload ?? item.title,
            header: item.header === true
        };
    }

    // Writes the answer and releases the caller. An empty string is a
    // cancellation: the caller sees a closed connection with no output and
    // exits 1, exactly as `wofi --dmenu` does on Esc.
    function respond(text: string): void {
        const sock = root.activeSocket;
        root.activeSocket = null;
        root.busy = false;
        root.prompt = "";
        root.items = [];
        root.breadcrumb = "";
        root.back = "";
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
                    root.breadcrumb = request.breadcrumb ?? "";
                    root.back = request.back ?? "";
                    root.items = (request.items ?? []).map(i => root.normalise(i)).filter(i => i !== null);
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
