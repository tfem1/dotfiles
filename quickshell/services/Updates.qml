pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Packages that can be updated (`tfem updates count`), counted shortly after
// login, then every hour. The bar shows an icon with the count; a click
// opens a terminal that updates them (`tfem updates install`), which asks
// the shell to count again (`qs ipc call updates refresh`).
Singleton {
    id: root

    property int count: 0
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"

    function refresh() {
        counter.running = true;
    }

    function install() {
        Quickshell.execDetached(["kitty", "--title", "Updates", root.cli, "updates", "install"]);
    }

    Process {
        id: counter
        command: [root.cli, "updates", "count"]
        stdout: StdioCollector {
            onStreamFinished: root.count = parseInt(text) || 0
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 60 * 60 * 1000
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    Timer {   // not at the very start of the session: it can be busy
        running: true
        interval: 2 * 60 * 1000
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "updates"
        function refresh(): void { root.refresh(); }
    }
}
