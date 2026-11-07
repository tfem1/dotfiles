import QtQuick
import Quickshell
import "../overlay"
import "search.js" as Search

// The app launcher (SUPER + D): search and open apps, best matches first
// (ranking in search.js). Only loaded while open.
Scope {
    id: root

    property bool open: false
    property string query: ""

    // Terminal apps (btop, nvim…) need a terminal: DesktopEntry.execute()
    // does not open one. Hyprland sets $TERMINAL (hypr/config/variables.lua).
    readonly property string terminal: Quickshell.env("TERMINAL") || "kitty"

    function toggle() {
        open = !open;
        query = "";
    }

    function launch(app) {
        if (app.runInTerminal)
            Quickshell.execDetached({
                command: [terminal].concat(Array.from(app.command)),
                workingDirectory: app.workingDirectory
            });
        else
            app.execute();
        open = false;
    }

    readonly property var matches: open ? Search.rank(DesktopEntries.applications.values, query, 50) : []

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "launcher"
            onDismissed: root.open = false

            LauncherContent {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.2
                width: 560
                height: implicitHeight
                apps: root.matches.map(app => ({
                    name: app.name,
                    comment: app.genericName || app.comment,
                    iconSource: Quickshell.iconPath(app.icon, true)
                }))
                onQueryChanged: root.query = query
                onLaunched: index => root.launch(root.matches[index])
                onClosed: root.open = false
                Component.onCompleted: focusSearch()
            }
        }
    }
}
