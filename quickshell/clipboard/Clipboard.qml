import QtQuick
import Quickshell
import Quickshell.Io
import "../overlay"

// Clipboard history (SUPER + C), kept by cliphist, which Hyprland starts.
// Enter copies the chosen entry again. Only loaded while open; the history
// is read each time it opens, never polled.
Scope {
    id: root

    property bool open: false
    property string query: ""
    property var entries: [] // [{ line, text, image }]

    function toggle() {
        open = !open;
        query = "";
        if (open)
            history.running = true;
    }

    // "<id>\t<preview>" lines from `cliphist list`; images read
    // "[[ binary data 32 KiB png 1920x1080 ]]".
    function parse(output) {
        return output.split("\n").filter(line => line.includes("\t")).map(line => {
            const preview = line.slice(line.indexOf("\t") + 1);
            const binary = /^\[\[ binary data (.*) \]\]$/.exec(preview);
            return { line: line, text: binary ? "Image · " + binary[1] : preview, image: !!binary };
        });
    }

    // The whole line goes back through `cliphist decode`, as in its README.
    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "sh", entry.line]);
        open = false;
    }

    readonly property var matches: {
        const text = query.trim().toLowerCase();
        return entries.filter(entry => !text || entry.text.toLowerCase().includes(text)).slice(0, 100);
    }

    Process {
        id: history
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "clipboard"
            onDismissed: root.open = false

            ClipboardContent {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.2
                width: 560
                height: implicitHeight
                entries: root.matches
                onQueryChanged: root.query = query
                onChosen: index => root.copy(root.matches[index])
                onClosed: root.open = false
                Component.onCompleted: focusSearch()
            }
        }
    }
}
