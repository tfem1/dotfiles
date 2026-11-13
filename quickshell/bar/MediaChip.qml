import QtQuick
import "../theme"
import "../components"

// Now playing: a note, the title (or "Nothing playing"), then a small
// play/pause button. Only the button when `vertical`.
Pill {
    id: chip

    property string title: ""
    property string artist: ""
    property real progress: 0
    property bool playing: false
    signal toggle

    padding: 6
    spacing: 10
    onClicked: toggle()

    Icon {
        visible: !chip.vertical
        name: "music_note"
        color: Theme.modules.media
        size: 16
    }
    Label {
        visible: !chip.vertical
        width: Math.min(200, implicitWidth)
        text: chip.title || "Nothing playing"
        font.weight: Font.DemiBold
        color: chip.title ? Theme.fgBright : Theme.fg
        elide: Text.ElideRight
    }
    Rectangle {   // the button, filled as far as the song has played
        width: 30
        height: 22
        radius: 11
        color: Qt.alpha(Theme.modules.media, 0.22)
        clip: true

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, chip.progress))
            height: parent.height
            color: Qt.alpha(Theme.modules.media, 0.35)
        }
        Icon {
            anchors.centerIn: parent
            name: chip.playing ? "pause" : "play_arrow"
            color: Theme.modules.media
            size: 15
        }
    }
}
