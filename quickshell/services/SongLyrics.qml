pragma Singleton
import QtQuick
import Quickshell
import "../theme"
import "../music"
import "../music/lyrics.js" as LyricsLib

// The lyrics of the song playing, fetched once for everything that shows
// them (the bar's lyrics module, the music and lyrics widgets), and only
// while one of them is on. `line`: the line being sung ("" without synced
// lyrics or between lines).
Singleton {
    id: root

    readonly property bool wanted: String(Theme.bar.layout || "").indexOf("lyrics") >= 0
        || !!(Theme.widgets && (Theme.widgets.lyrics || Theme.widgets.media))
    readonly property var lyrics: source.lyrics
    readonly property var lines: source.lyrics.kind === "synced" ? source.lyrics.lines : []
    readonly property int at: Player.player ? LyricsLib.current(lines, Player.player.position) : -1
    readonly property string line: at >= 0 ? lines[at].text : ""

    LyricsSource {
        id: source
        player: Player.player
        active: root.wanted && Player.active
    }
}
