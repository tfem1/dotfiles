import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../services"
import "../music"
import "../music/lyrics.js" as Lyrics
import "resources.js" as Resources

// The desktop widgets, on the first screen, in the corner picked in the
// Settings (Widgets), under the windows: they take no clicks. In game mode
// they hide and stop, so the game gets that time. What feeds them runs only while they show: the resource readings
// for the rings, cava for the spectrum (stopped in game mode), lrclib for
// the lyrics of the song playing.
Scope {
    id: root

    readonly property var show: Theme.widgets
    readonly property string corner: show.corner || "top-left"
    readonly property bool resources: !!(show.cpu || show.gpu || show.ram || show.disk)
    readonly property bool any: resources || !!(show.clock || show.audio || show.media)
    property var levels: Resources.spectrum("", 24)

    ResourceMonitor {
        id: monitor
        running: root.resources && !Theme.gameMode
        wantGpu: !!root.show.gpu
        wantDisk: !!root.show.disk
    }

    LyricsSource {
        id: lyrics
        player: Player.player
        active: !!root.show.media && Player.active && !Theme.gameMode
    }

    Process {
        running: !!root.show.audio && !Theme.gameMode
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

    LazyLoader {
        active: root.any && !Theme.gameMode

        PanelWindow {
            screen: Quickshell.screens[0] || null
            aboveWindows: false
            exclusionMode: ExclusionMode.Normal
            anchors {
                top: root.corner.startsWith("top")
                bottom: root.corner.startsWith("bottom")
                left: root.corner.endsWith("left")
                right: root.corner.endsWith("right")
            }
            // The bar's space is kept free (ExclusionMode.Normal): these
            // margins count from it at the top.
            margins {
                top: 16
                bottom: 24
                left: 24
                right: 24
            }
            implicitWidth: content.width
            implicitHeight: content.implicitHeight
            color: "transparent"
            mask: Region {}

            WidgetsContent {
                id: content

                readonly property var player: Player.player
                readonly property var lines: lyrics.lyrics.kind === "synced" ? lyrics.lyrics.lines : []
                readonly property int at: player ? Lyrics.current(lines, player.position) : -1

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
                    line: at >= 0 ? lines[at].text : "",
                    next: at >= 0 && at + 1 < lines.length ? lines[at + 1].text : ""
                })
            }
        }
    }
}
