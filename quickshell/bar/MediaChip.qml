import QtQuick
import "../theme"
import "../components"

// Now playing: a progress ring around play/pause, then title and artist.
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
        anchors.verticalCenter: parent.verticalCenter
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
        anchors.verticalCenter: parent.verticalCenter
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
