import QtQuick
import "../theme"

// An on/off switch in a given color (solid colors, no gradient).
Rectangle {
    id: toggle

    property bool checked: false
    property color tint: Theme.accent
    signal toggled(bool checked)

    width: 40
    height: 22
    radius: height / 2
    color: checked ? tint : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - 3 : 3
        color: toggle.checked ? Theme.bg : Theme.subtle
        Behavior on x { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    }

    TapHandler { onTapped: toggle.toggled(!toggle.checked) }
}
