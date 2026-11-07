import QtQuick
import Quickshell
import Quickshell.Io
import "../overlay"

// The keybind cheatsheet (SUPER + /), read from Hyprland itself, so it lists
// your own binds too. Read each time it opens; only loaded while open.
Scope {
    id: root

    property bool open: false
    property var binds: []

    function toggle() {
        open = !open;
        if (open)
            reader.running = true;
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = JSON.parse(text);
                } catch (error) {
                    console.warn("cheatsheet: cannot read hyprctl binds:", error);
                    root.binds = [];
                }
            }
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "cheatsheet"
            onDismissed: root.open = false

            CheatsheetContent {
                anchors.centerIn: parent
                width: implicitWidth
                height: implicitHeight
                binds: root.binds
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
