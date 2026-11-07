import QtQuick
import "../theme"
import "../components"

// The album sleeve with its record sliding out on the right. The record
// turns while the music plays and stops where it is on pause. The label
// takes the theme's third color (used sparingly).
Item {
    id: vinyl

    property url artUrl
    property bool playing: false
    property int size: 170

    implicitWidth: size * 1.55
    implicitHeight: size

    Item {
        id: disc
        x: vinyl.size * 0.55
        width: vinyl.size
        height: vinyl.size

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 4800
            loops: Animation.Infinite
            running: true
            paused: !vinyl.playing
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.variant === "dark" ? Theme.bgAlt : Theme.fg
        }
        // Grooves.
        Repeater {
            model: [0.92, 0.82, 0.72, 0.62]
            Rectangle {
                id: groove
                required property real modelData
                anchors.centerIn: parent
                width: disc.width * groove.modelData
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Theme.subtle, 0.25)
            }
        }
        // Label, with a light mark so the turn shows.
        Rectangle {
            anchors.centerIn: parent
            width: disc.width * 0.36
            height: width
            radius: width / 2
            color: Theme.modules.media

            Rectangle {
                x: parent.width * 0.5 - width / 2
                y: parent.height * 0.14
                width: 4
                height: parent.height * 0.18
                radius: 2
                color: Qt.alpha(Theme.bg, 0.55)
            }
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Theme.bg
            }
        }
    }

    // The sleeve: the album art, or a note on the theme's surface.
    Rectangle {
        width: vinyl.size
        height: vinyl.size
        radius: 10
        color: Theme.surface

        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            name: "music_note"
            color: Theme.modules.media
            size: vinyl.size * 0.3
        }
        Image {
            id: art
            anchors.fill: parent
            source: vinyl.artUrl
            sourceSize: Qt.size(vinyl.size * 2, vinyl.size * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
