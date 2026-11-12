import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "dock.js" as DockLib

// The dock on each screen (Settings → Dock): pinned apps and running ones.
// A click opens the app, or brings its window forward (again: the next
// one); a right click pins or unpins it. The windows come from Wayland
// (ToplevelManager), names and icons from the desktop files (DesktopEntries).
// Colors follow the theme; dock.opacity sets how see-through it is. With
// autohide it slides in when the pointer touches its screen edge.
Scope {
    id: root

    readonly property var settings: Theme.dock
    readonly property string edge: ["bottom", "left", "right"].includes(settings.position) ? settings.position : "bottom"
    readonly property var windows: ToplevelManager.toplevels.values
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"
    readonly property var apps: DockLib.items(settings.pinned, windows.map(window => ({
        appId: window.appId, activated: window.activated
    }))).map(item => {
        const entry = DesktopEntries.byId(item.id) || DesktopEntries.heuristicLookup(item.id);
        return Object.assign(item, {
            name: entry ? entry.name : item.id,
            icon: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
        });
    })

    function activate(id) {
        const index = DockLib.nextWindow(windows.map(window => ({ appId: window.appId, activated: window.activated })), id);
        if (index >= 0) {
            windows[index].activate();
            return;
        }
        const entry = DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id);
        if (entry)
            entry.execute();
    }

    function togglePin(id) {
        const pinned = DockLib.togglePin(settings.pinned, id);
        Theme.dock = Object.assign({}, Theme.dock, { pinned: pinned });   // at once
        Quickshell.execDetached([cli, "settings", "set", "dock.pinned=" + pinned]);
    }

    Variants {
        model: root.settings.enabled ? Quickshell.screens : []

        PanelWindow {
            id: window

            required property var modelData
            readonly property bool revealed: !root.settings.autohide || hover.hovered || hideDelay.running

            screen: modelData
            anchors {
                bottom: root.edge === "bottom"
                left: root.edge === "left"
                right: root.edge === "right"
            }
            margins {
                bottom: root.edge === "bottom" ? 8 : 0
                left: root.edge === "left" ? 8 : 0
                right: root.edge === "right" ? 8 : 0
            }
            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight
            color: "transparent"
            exclusionMode: root.settings.autohide ? ExclusionMode.Ignore : ExclusionMode.Auto
            // Hidden: only a thin strip on the screen edge takes the pointer.
            mask: Region { item: window.revealed ? content : strip }
            WlrLayershell.namespace: "shell-dock"

            Timer {
                id: hideDelay
                interval: 500
            }

            DockContent {
                id: content
                edge: root.edge
                fill: root.settings.opacity
                apps: root.apps
                // Hidden: slid out past the screen edge.
                x: root.edge === "left" ? (window.revealed ? 0 : -width - 8)
                    : root.edge === "right" ? (window.revealed ? 0 : width + 8) : 0
                y: root.edge === "bottom" ? (window.revealed ? 0 : height + 8) : 0
                Behavior on x { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
                onActivated: id => root.activate(id)
                onPinToggled: id => root.togglePin(id)
            }

            Item {
                id: strip
                x: root.edge === "right" ? parent.width - width : 0
                y: root.edge === "bottom" ? parent.height - height : 0
                width: root.edge === "bottom" ? parent.width : 2
                height: root.edge === "bottom" ? 2 : parent.height
            }

            // Keeps the dock out a moment after the pointer leaves it.
            HoverHandler {
                id: hover
                onHoveredChanged: if (!hovered) hideDelay.restart()
            }
        }
    }
}
