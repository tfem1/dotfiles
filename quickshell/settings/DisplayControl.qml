import QtQuick
import Quickshell
import Quickshell.Io

// The Display page's side: reads the screens with `tfem display list`,
// applies a mode with `tfem display set` (Hyprland reloads at once), then
// waits 15 seconds for Keep; without it, the previous mode comes back. It
// lives outside the window, so it goes back even when the window is closed
// or the screen shows nothing.
Scope {
    id: control

    required property string cli
    property var listing: ({ monitors: [], chosen: {} })
    property var confirm: null      // { name, previous, seconds }
    property var queued: null       // the command waiting for the one running

    function refresh() {
        reader.running = true;
    }

    // `mode`: "WxH@R" or "auto" (the highest refresh rate).
    function apply(name, mode, ask) {
        // Several tries in a row go back to the mode before the first one.
        const previous = confirm && confirm.name === name ? confirm.previous : (listing.chosen || {})[name] || "auto";
        confirm = ask ? { name: name, previous: previous, seconds: 15 } : null;
        countdown.running = ask;
        // The chips show the new mode at once; the screens are read again
        // once it is applied.
        const chosen = Object.assign({}, listing.chosen);
        if (mode === "auto")
            delete chosen[name];
        else
            chosen[name] = mode;
        listing = Object.assign({}, listing, { chosen: chosen });
        run([cli, "display"].concat(mode === "auto" ? ["auto", name] : ["set", name, mode]));
    }

    function run(command) {
        if (writer.running) {
            queued = command;
            return;
        }
        writer.command = command;
        writer.running = true;
    }

    function keep() {
        confirm = null;
        countdown.running = false;
    }

    function revert() {
        if (confirm)
            apply(confirm.name, confirm.previous, false);
    }

    Process {
        id: reader
        command: [control.cli, "display", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    control.listing = JSON.parse(text);
                } catch (error) {
                    console.warn("display: cannot read the screens:", error);
                }
            }
        }
    }

    Process {
        id: writer
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0)
                console.warn("display: not applied:", errors.text.trim());
            if (control.queued) {
                const next = control.queued;
                control.queued = null;
                control.run(next);
            } else {
                settle.restart();
            }
        }
    }

    // The screen takes a moment to switch: read the modes after it.
    Timer {
        id: settle
        interval: 1200
        onTriggered: control.refresh()
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: {
            if (!control.confirm) {
                running = false;
            } else if (control.confirm.seconds <= 1) {
                running = false;
                control.revert();
            } else {
                control.confirm = Object.assign({}, control.confirm, { seconds: control.confirm.seconds - 1 });
            }
        }
    }
}
