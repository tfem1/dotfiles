pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "lyrics.js" as Lyrics

// The music panel (SUPER + M): sleeve and turning record, title, progress
// (click to move in the song), controls, the players to choose from, and
// the lyrics on request. Plain data in, requests out (MusicPanel.qml).
// track: { title, artist, album, artUrl, playing, position, length, canSeek,
//          canGoNext, canGoPrevious, shuffle (null: not supported), loop
//          ("none" | "track" | "playlist" | "")}; players: [{ name, current }]
// lyrics: { kind: "off" | "loading" | "synced" | "plain" | "instrumental" | "none", lines }
Rectangle {
    id: panel

    property var track: ({ title: "", artist: "", album: "", playing: false, position: 0, length: 0 })
    property var players: []
    property var lyrics: ({ kind: "off", lines: [] })
    signal togglePlaying
    signal next
    signal previous
    signal seek(real seconds)
    signal shuffleToggled
    signal loopCycled
    signal playerChosen(int index)
    signal lyricsToggled(bool show)
    signal closed

    // The main color for the controls; the third color stays on the record's label.
    readonly property color tint: Theme.accent
    readonly property bool showLyrics: lyrics.kind !== "off"
    readonly property int sung: Lyrics.current(lyrics.lines, track.position)

    implicitWidth: 520
    implicitHeight: column.implicitHeight + 36
    radius: Theme.radius + 8
    color: Theme.panel
    focus: true
    Keys.onEscapePressed: closed()
    Keys.onSpacePressed: togglePlaying()

    // Keeps clicks inside from closing it.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: column
        x: 18
        y: 18
        width: parent.width - 36
        spacing: 14

        Row {
            spacing: 16

            Vinyl {
                artUrl: panel.track.artUrl || ""
                playing: panel.track.playing
                size: 150
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: column.width - 150 * 1.55 - 16
                spacing: 4

                Label {
                    width: parent.width
                    text: panel.track.title || "Nothing playing"
                    textFormat: Text.PlainText
                    color: Theme.fgBright
                    font.pixelSize: Math.round(Theme.fontPixels * 1.25)
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }
                Label {
                    width: parent.width
                    text: panel.track.artist || ""
                    textFormat: Text.PlainText
                    color: panel.tint
                }
                Label {
                    width: parent.width
                    text: panel.track.album || ""
                    textFormat: Text.PlainText
                    small: true
                }
            }
        }

        // Progress: click or drag to move in the song (when the player allows it).
        Column {
            width: parent.width
            spacing: 2
            Slider {
                width: parent.width
                value: panel.track.length > 0 ? panel.track.position / panel.track.length : 0
                tint: panel.tint
                enabled: !!panel.track.canSeek
                onMoved: value => panel.seek(value * panel.track.length)
            }
            Item {
                width: parent.width
                height: 16
                Label { text: Lyrics.clock(panel.track.position); small: true }
                Label { anchors.right: parent.right; text: Lyrics.clock(panel.track.length); small: true }
            }
        }

        Item {
            width: parent.width
            height: 52

            Row {
                anchors.centerIn: parent
                spacing: 10

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: panel.track.shuffle !== null && panel.track.shuffle !== undefined
                    icon: "shuffle"
                    tint: panel.track.shuffle ? panel.tint : Theme.subtle
                    onClicked: panel.shuffleToggled()
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_previous"
                    size: 40
                    tint: panel.track.canGoPrevious === false ? Theme.muted : Theme.fg
                    onClicked: panel.previous()
                }
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    color: panel.tint
                    Icon {
                        anchors.centerIn: parent
                        name: panel.track.playing ? "pause" : "play_arrow"
                        color: Theme.bg
                        size: 28
                    }
                    TapHandler { onTapped: panel.togglePlaying() }
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_next"
                    size: 40
                    tint: panel.track.canGoNext === false ? Theme.muted : Theme.fg
                    onClicked: panel.next()
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!panel.track.loop
                    icon: panel.track.loop === "track" ? "repeat_one" : "repeat"
                    tint: panel.track.loop === "none" ? Theme.subtle : panel.tint
                    onClicked: panel.loopCycled()
                }
            }
            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: "lyrics"
                tint: panel.showLyrics ? panel.tint : Theme.subtle
                onClicked: panel.lyricsToggled(!panel.showLyrics)
            }
        }

        // The players to choose from, when there are several.
        Flow {
            visible: panel.players.length > 1
            width: parent.width
            spacing: 6
            Repeater {
                model: panel.players
                Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    width: chipLabel.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: modelData.current ? Qt.alpha(panel.tint, 0.22) : Theme.bgAlt
                    Label {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: chip.modelData.name
                        small: true
                        color: chip.modelData.current ? Theme.fgBright : Theme.subtle
                    }
                    TapHandler { onTapped: panel.playerChosen(chip.index) }
                }
            }
        }

        LyricsView {
            visible: panel.showLyrics
            width: parent.width
            height: 200
            lyrics: panel.lyrics
            sung: panel.sung
        }
    }
}
