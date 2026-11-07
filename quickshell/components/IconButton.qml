import QtQuick
import "../theme"

// A round button with an icon; `spinning` turns it (scan in progress).
Rectangle {
    id: button

    property string icon: ""
    property color tint: Theme.fg
    property bool spinning: false
    property int size: 32
    signal clicked

    width: size
    height: size
    radius: size / 2
    color: hover.hovered ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Icon {
        id: glyph
        anchors.centerIn: parent
        name: button.icon
        color: button.tint
        size: Math.round(button.size * 0.56)

        RotationAnimator on rotation {
            running: button.spinning
            from: 0
            to: 360
            duration: 1200
            loops: Animation.Infinite
            onStopped: glyph.rotation = 0
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: button.clicked() }
}
