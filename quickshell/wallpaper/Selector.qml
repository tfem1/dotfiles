import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../overlay"

// The wallpaper selector (SUPER + W). The list comes from
// `tfem wallpapers list`, a pick goes through `tfem wallpapers set`, which
// saves it in theme.toml and regenerates the files that show it (this
// shell's wallpaper, the lock screen); a wallpaper of the collection also
// brings its theme (a cat, Tabby), any other image a theme made from its own
// colors (read here, passed with --colors), then the whole desktop recolors.
// Recent picks and the colors of each image are kept in the shell's state
// folder. Only loaded while open.
Scope {
    id: root

    property bool open: false
    property var images: []    // [{ path, name, category, theme }]
    property var colors: ({})  // path -> color class, found once per image
    property var palettes: ({}) // path -> its 8 main colors, "#rrggbb,..."
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
        const palette = palettes[path];
        Quickshell.execDetached([cli, "wallpapers", "set", path].concat(palette ? ["--colors", palette] : []));
        recent = [path].concat(recent.filter(other => other !== path)).slice(0, 30);
        save();
    }

    function remember(path, color, palette) {
        const known = Object.assign({}, colors);
        known[path] = color;
        colors = known;
        const read = Object.assign({}, palettes);
        read[path] = palette;
        palettes = read;
        saveSoon.restart();
    }

    function save() {
        state.setText(JSON.stringify({ recent: recent, colors: colors, palettes: palettes }));
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
                root.palettes = data.palettes || {};
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
        queue: root.open ? root.images.map(image => image.path).filter(path => !(path in root.palettes)) : []
        onSampled: (path, color, palette) => root.remember(path, color, palette)
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
