pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The music widget: the cover in a scalloped shape, a wave around it as far
// as the song has played, the title, a wavy progress line and the controls
// (previous, 10 s back, play or pause, 10 s on, next). `player` is the
// MPRIS player (none in the preview: the buttons then do nothing).
WidgetCard {
    id: card

    property string song: ""
    property string artist: ""
    property url art
    property bool playing: false
    property real progress: 0
    property var player: null

    component Control: Rectangle {
        property string icon: ""
        property bool main: false
        signal clicked
        width: main ? 48 : 30
        height: main ? 32 : 30
        radius: main ? 12 : 15
        color: main ? Qt.alpha(Theme.accent, 0.45) : hover.hovered ? Theme.surface : Qt.alpha(Theme.surface, 0.55)
        Icon {
            anchors.centerIn: parent
            name: parent.icon
            color: parent.main ? Theme.fgBright : Theme.fg
            size: parent.main ? 18 : 15
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: parent.clicked() }
    }

    Column {
        width: parent.width
        spacing: 10

        Item {
            width: parent.width
            height: 172
            WavyRing {
                anchors.centerIn: parent
                width: 172
                height: 172
                progress: card.progress
                moving: card.playing
            }
            CoverArt {
                anchors.centerIn: parent
                width: 134
                height: 134
                source: card.art
            }
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: card.song || "Nothing playing"
            color: Theme.fgBright
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Label {
            width: parent.width
            visible: text !== ""
            horizontalAlignment: Text.AlignHCenter
            text: card.artist
            small: true
            elide: Text.ElideRight
        }
        WavyLine {
            width: parent.width
            progress: card.progress
            moving: card.playing
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Control { icon: "skip_previous"; onClicked: if (card.player && card.player.canGoPrevious) card.player.previous() }
            Control { icon: "fast_rewind"; onClicked: if (card.player && card.player.canSeek) card.player.seek(-10) }
            Control {
                main: true
                icon: card.playing ? "pause" : "play_arrow"
                onClicked: if (card.player && card.player.canTogglePlaying) card.player.togglePlaying()
            }
            Control { icon: "fast_forward"; onClicked: if (card.player && card.player.canSeek) card.player.seek(10) }
            Control { icon: "skip_next"; onClicked: if (card.player && card.player.canGoNext) card.player.next() }
        }
    }
}
