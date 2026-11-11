import QtQuick
import "../theme"

// The moon of the welcome banner, drawn with circles in the theme's
// colors: a halo, the disc, a few craters and stars around it.
Item {
    id: moon

    property real size: 120

    implicitWidth: size * 1.9
    implicitHeight: size * 1.5

    // Stars: [x, y, size] as parts of the item.
    Repeater {
        model: [[0.06, 0.18, 4], [0.18, 0.78, 3], [0.88, 0.1, 5], [0.95, 0.62, 3], [0.3, 0.06, 3], [0.8, 0.9, 4]]

        Rectangle {
            required property var modelData
            x: moon.width * modelData[0]
            y: moon.height * modelData[1]
            width: modelData[2]
            height: width
            radius: width / 2
            color: Theme.fgBright
            opacity: 0.8
        }
    }

    Rectangle {
        anchors.centerIn: disc
        width: moon.size * 1.45
        height: width
        radius: width / 2
        color: Qt.alpha(Theme.fgBright, 0.08)
    }

    Rectangle {
        id: disc
        anchors.centerIn: parent
        width: moon.size
        height: width
        radius: width / 2
        color: Theme.fgBright

        // Craters: [x, y, size] as parts of the disc.
        Repeater {
            model: [[0.22, 0.28, 0.22], [0.58, 0.18, 0.12], [0.52, 0.55, 0.26], [0.2, 0.66, 0.12], [0.76, 0.42, 0.09]]

            Rectangle {
                required property var modelData
                x: disc.width * modelData[0]
                y: disc.height * modelData[1]
                width: disc.width * modelData[2]
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.bg, 0.13)
            }
        }
    }
}
