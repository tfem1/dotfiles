import QtQuick
import "../theme"

// A horizontal slider from 0 to 1 in a given color: click or drag to set
// it, the mouse wheel moves it by 5 %. `moved(value)` reports each change;
// `value` follows the outside (it is not changed by the slider itself).
Item {
    id: slider

    property real value: 0
    property color tint: Theme.accent
    property bool dimmed: false   // muted: drawn in the theme's quiet color
    signal moved(real value)

    function set(x) {
        moved(Math.max(0, Math.min(1, x / width)));
    }

    implicitHeight: 24

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface

        Rectangle {
            width: Math.max(height, parent.width * slider.value)
            height: parent.height
            radius: parent.radius
            color: slider.dimmed ? Theme.muted : slider.tint
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(slider.width - width, slider.width * slider.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: slider.dimmed ? Theme.subtle : Theme.fgBright
        scale: drag.active || hover.hovered ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.duration } }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: point => slider.set(point.position.x) }
    DragHandler {
        id: drag
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        onCentroidChanged: if (active) slider.set(centroid.position.x)
    }
    WheelHandler {
        onWheel: event => slider.moved(Math.max(0, Math.min(1, slider.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
