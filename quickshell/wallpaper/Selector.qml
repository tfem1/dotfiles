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
// folder. Only loaded while open. It shows small copies of the images
// (`tfem wallpapers thumbs`, made in the background once): a 4K image takes
// long to decode, and a dozen of them froze the screen on opening.
Scope {
    id: root

    property bool open: false
    property var images: []    // [{ path, name, category, theme, thumb }]
    property var colors: ({})  // path -> color class, found once per image
    property var palettes: ({}) // path -> its 8 main colors, "#rrggbb,..."
    property string waiting: ""  // picked before its colors were read: applied once they are
    property var recent: []    // paths, newest first
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"

    function toggle() {
        open = !open;
        if (open)
            lister.running = true;
        else
            save();
    }

    // The theme is made from the image's colors: they are read first if needed.
    function apply(path) {
        if (!(path in palettes)) {
            waiting = path;
            return;
        }
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
        if (path === waiting) {
            waiting = "";
            apply(path);
        }
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
                    // The same list again keeps the cards as they are.
                    if (text !== root.listed) {
                        root.listed = text;
                        root.images = JSON.parse(text);
                    }
                    if (root.images.some(image => !image.thumb) && !root.thumbsTried)
                        thumbs.running = true;
                } catch (error) {
                    console.warn("wallpaper: cannot read the list:", error);
                }
            }
        }
    }

    property string listed: ""
    property bool thumbsTried: false   // once per session: without ffmpeg, none come

    Process {
        id: thumbs
        command: ["nice", "-n", "19", root.cli, "wallpapers", "thumbs"]
        onRunningChanged: if (running) root.thumbsTried = true
        onExited: lister.running = true
    }

    // Shortly after login, the small copies are made if some are missing,
    // so even the first opening is quick.
    Timer {
        running: true
        interval: 30000
        onTriggered: lister.running = true
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

    // Colors are read in the background, one image after the other.
    ColorProbe {
        // While open, every image; the one picked and waiting, first and even
        // once the selector is closed.
        queue: (root.waiting ? [root.waiting] : []).concat(root.open
            ? root.images.map(image => image.path).filter(path => !(path in root.palettes) && path !== root.waiting) : [])
        thumbs: root.images.reduce((map, image) => (map[image.path] = image.thumb, map), {})
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
