import QtQuick
import "../theme"
import "../components"

// Now playing: a progress ring around play/pause, then title and artist
// (only the ring when `vertical`).
Pill {
    id: chip

    property string title: ""
    property string artist: ""
    property real progress: 0
    property bool playing: false
    signal toggle

    padding: 6
    onClicked: toggle()

    RingProgress {
        value: chip.progress
        color: Theme.modules.media
        track: Theme.surface

        Icon {
            anchors.centerIn: parent
            name: chip.playing ? "pause" : "play_arrow"
            color: Theme.modules.media
            size: 16
        }
    }

    Column {
        visible: !chip.vertical    // the ring alone on a bar at the side
        width: Math.min(220, Math.max(titleLabel.implicitWidth, artistLabel.implicitWidth))
        rightPadding: 6

        Label {
            id: titleLabel
            width: parent.width
            text: chip.title
            font.weight: Font.Medium
        }
        Label {
            id: artistLabel
            width: parent.width
            text: chip.artist
            small: true
        }
    }
}
