import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// The app launcher (SUPER + D): desktop apps matching the search, best
// matches first. Only loaded while open.
Scope {
    id: root

    property bool open: false
    property string query: ""

    function toggle() {
        open = !open;
        query = "";
    }

    // 3: name starts with the query, 2: name contains it, 1: other fields do.
    function score(app, text) {
        if (!text)
            return 1;
        const name = app.name.toLowerCase();
        if (name.startsWith(text))
            return 3;
        if (name.includes(text))
            return 2;
        const extra = [app.genericName, app.comment].concat(app.keywords).join(" ").toLowerCase();
        return extra.includes(text) ? 1 : 0;
    }

    readonly property var matches: {
        if (!open)
            return [];
        const text = query.trim().toLowerCase();
        return DesktopEntries.applications.values
            .filter(app => !app.noDisplay)
            .map(app => ({ app: app, score: score(app, text) }))
            .filter(match => match.score > 0)
            .sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name))
            .slice(0, 50)
            .map(match => match.app);
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: Qt.alpha(Theme.bgAlt, 0.45)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "shell-launcher"

            // A click outside the box closes the launcher.
            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

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
                onLaunched: index => {
                    root.matches[index].execute();
                    root.open = false;
                }
                onClosed: root.open = false
                Component.onCompleted: focusSearch()
            }
        }
    }
}
