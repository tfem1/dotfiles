import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"
import "../music"
import "../music/lyrics.js" as Lyrics
import "resources.js" as Resources

// The desktop widgets, on the first screen, in the corner picked in the
// Settings (Widgets) or where you dragged them, under the windows: they
// take no clicks, except while you move them (Settings → Widgets → Move,
// or `qs ipc call widgets edit`). In game mode,
// power saver, focus and presentation they hide and stop. What feeds them runs only while they show: the resource readings
// for the rings, cava for the spectrum (stopped in game mode), lrclib for
// the lyrics of the song playing.
Scope {
    id: root

    readonly property var show: Theme.widgets
    readonly property string corner: show.corner || "top-left"
    readonly property bool resources: !!(show.cpu || show.gpu || show.ram || show.disk)
    readonly property bool any: resources || !!(show.clock || show.audio || show.media || show.lyrics)
    readonly property bool paused: Theme.gameMode || Theme.powerSaver || Session.focus || Session.presentation
    property var levels: Resources.spectrum("", 24)

    ResourceMonitor {
        id: monitor
        running: root.resources && !root.paused
        wantGpu: !!root.show.gpu
        wantDisk: !!root.show.disk
    }

    Process {
        running: !!root.show.audio && !root.paused
        command: ["cava", "-p", Quickshell.shellDir + "/widgets/cava.conf"]
        stdout: SplitParser {
            onRead: data => root.levels = Resources.spectrum(data, 24)
        }
        onRunningChanged: if (!running) root.levels = Resources.spectrum("", 24)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Editing: the widgets come above the windows and take the pointer.
    property bool editing: false

    function edit() {
        editing = true;
    }

    function save(pairs) {
        Quickshell.execDetached([cli, "settings", "set"].concat(pairs));
    }

    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"

    IpcHandler {
        target: "widgets"

        function edit(): void {
            root.edit();
        }
    }

    LazyLoader {
        active: (root.any && !root.paused) || root.editing

        PanelWindow {
            screen: Quickshell.screens[0] || null
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            // The bar's space stays free (ExclusionMode.Normal).
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: root.editing ? WlrLayer.Top : WlrLayer.Bottom
            WlrLayershell.keyboardFocus: root.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "glass-widgets"   // its own blur rule (theme.lua)
            color: "transparent"
            // Only while editing do they take clicks.
            mask: root.editing ? null : noInput
            Region { id: noInput }

            WidgetsDesktop {
                id: content

                readonly property var player: Player.player
                readonly property var lines: SongLyrics.lines   // fetched once, shared with the bar
                readonly property int at: player ? Lyrics.current(lines, player.position) : -1

                anchors.fill: parent
                editing: root.editing
                places: root.show.places || {}
                show: root.show
                now: clock.date
                cpu: monitor.cpu
                gpu: monitor.gpu
                ram: monitor.ram
                disk: monitor.disk
                levels: root.levels
                device: Audio.sink ? (Audio.sink.description || Audio.sink.nickname || Audio.sink.name) : ""
                hasMedia: Player.active
                media: ({
                    song: Player.title,
                    artist: Player.artist,
                    art: player ? player.trackArtUrl : "",
                    playing: Player.playing,
                    progress: Player.progress,
                    player: player,
                    synced: lines.length > 0,
                    // The current line (offset 0), the two before and the two after.
                    lines: [-2, -1, 0, 1, 2].filter(offset => at + offset >= 0 && at + offset < lines.length)
                        .map(offset => ({ text: lines[at + offset].text, offset: offset }))
                })
                onMoved: (name, x, y) => {
                    const places = Object.assign({}, root.show.places || {}, { [name]: [x, y] });
                    Theme.widgets = Object.assign({}, Theme.widgets, { places: places });
                    root.save([`widgets.places.${name}=${x},${y}`]);
                }
                onReset: {
                    Theme.widgets = Object.assign({}, Theme.widgets, { places: {} });
                    root.save(["clock", "resources", "audio", "media", "lyrics", "calendar"].map(name => `widgets.places.${name}=auto`));
                }
                onDone: root.editing = false
            }
        }
    }
}
