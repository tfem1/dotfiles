import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../overlay"

// The wallpaper selector (SUPER + W). The list comes from
// `tfem wallpapers list`, a pick goes through `tfem wallpapers set`, which
// saves it in theme.toml and regenerates the files that show it (this
// shell's wallpaper, the lock screen). Recent picks and the color of each
// image are kept in the shell's state folder. Only loaded while open.
Scope {
    id: root

    property bool open: false
    property var images: []    // [{ path, name, category }]
    property var colors: ({})  // path -> color class, found once per image
    property var recent: []    // paths, newest first
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"

    function toggle() {
        open = !open;
        if (open)
            lister.running = true;
        else
            save();
    }

    function apply(path) {
        Quickshell.execDetached([cli, "wallpapers", "set", path]);
        recent = [path].concat(recent.filter(other => other !== path)).slice(0, 30);
        save();
    }

    function remember(path, color) {
        const known = Object.assign({}, colors);
        known[path] = color;
        colors = known;
        saveSoon.restart();
    }

    function save() {
        state.setText(JSON.stringify({ recent: recent, colors: colors }));
    }

    Process {
        id: lister
        command: [root.cli, "wallpapers", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.images = JSON.parse(text);
                } catch (error) {
                    console.warn("wallpaper: cannot read the list:", error);
                }
            }
        }
    }

    FileView {
        id: state
        path: Quickshell.statePath("wallpapers.json")
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.recent = data.recent || [];
                root.colors = data.colors || {};
            } catch (error) {
                console.warn("wallpaper: cannot read the saved state:", error);
            }
        }
    }

    // Colors arrive one by one: written once they stop for a moment.
    Timer {
        id: saveSoon
        interval: 1500
        onTriggered: root.save()
    }

    // Colors are looked for only while the selector is open.
    ColorProbe {
        queue: root.open ? root.images.map(image => image.path).filter(path => !(path in root.colors)) : []
        onSampled: (path, color) => root.remember(path, color)
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "wallpaper"
            onDismissed: root.open = false

            SelectorContent {
                anchors.fill: parent
                images: root.images
                colors: root.colors
                recent: root.recent
                current: Theme.wallpaper
                onApplied: (path, keepOpen) => {
                    root.apply(path);
                    if (!keepOpen)
                        root.open = false;
                }
                onClosed: root.open = false
            }
        }
    }
}
