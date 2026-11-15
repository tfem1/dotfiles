pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The lyrics widget: the cover and title on top, then the lines around the
// one being sung (it is larger and bright, the ones sung are dimmer), and
// the wavy progress line. `lines`: the two before, the current, the two
// after, as [{ text, offset }] (offset 0: the current one).
WidgetCard {
    id: card

    property string song: ""
    property url art
    property var lines: []
    property bool synced: false
    property bool playing: false
    property real progress: 0

    Column {
        width: parent.width
        spacing: 12

        Row {
            width: parent.width
            spacing: 12
            CoverArt {
                width: 40
                height: 40
                kind: "flower"
                source: card.art
            }
            Label {
                width: parent.width - 40 - 34 - 24
                anchors.verticalCenter: parent.verticalCenter
                text: card.song || "Nothing playing"
                color: Theme.fgBright
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 28
                radius: 10
                color: Qt.alpha(Theme.accent, 0.35)
                Icon {
                    anchors.centerIn: parent
                    name: "lyrics"
                    color: Theme.fgBright
                    size: 16
                }
            }
        }

        Column {
            width: parent.width
            spacing: 8
            Repeater {
                model: card.synced ? card.lines : []
                Label {
                    required property var modelData
                    width: parent.width
                    text: modelData.text || "♪"
                    wrapMode: Text.WordWrap
                    color: modelData.offset === 0 ? Theme.fgBright : modelData.offset < 0 ? Theme.subtle : Theme.fg
                    opacity: modelData.offset < 0 ? 0.7 : 1
                    font.pixelSize: modelData.offset === 0 ? Math.round(Theme.fontPixels * 1.35) : Theme.fontPixels
                    font.weight: modelData.offset === 0 ? Font.Bold : Font.Normal
                    Behavior on font.pixelSize { NumberAnimation { duration: Theme.duration } }
                }
            }
            Label {
                visible: !card.synced
                width: parent.width
                text: "No synced lyrics for this song"
                small: true
            }
        }

        WavyLine {
            width: parent.width
            progress: card.progress
            moving: card.playing
        }
    }
}
