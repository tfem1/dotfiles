import QtQuick
import "../theme"

// The sun of the welcome banner in the daytime (the moon at night), drawn
// with plain shapes: a halo, rays turning slowly
// around the disc, a few small clouds.
Item {
    id: sun

    property real size: 120
    // A real sun yellow in every theme (with 5 colors per theme, the theme's
    // "yellow" is one of its own colors), touched by the theme's accent.
    readonly property color gold: Qt.tint("#f2c14e", Qt.alpha(Theme.accent, 0.12))

    implicitWidth: size * 1.9
    implicitHeight: size * 1.5

    Rectangle {   // halo
        anchors.centerIn: disc
        width: sun.size * 1.55
        height: width
        radius: width / 2
        color: Qt.alpha(sun.gold, 0.12)
    }

    Item {   // rays, turning slowly (not with animations off)
        id: rays
        anchors.centerIn: disc
        width: sun.size * 1.5
        height: width
        RotationAnimation on rotation {
            running: Theme.animations
            from: 0
            to: 360
            duration: 60000
            loops: Animation.Infinite
        }

        Repeater {
            model: 12
            Rectangle {
                required property int index
                x: rays.width / 2 - width / 2
                y: 0
                width: sun.size * 0.07
                height: sun.size * 0.16
                radius: width / 2
                color: sun.gold
                transform: Rotation { origin.x: width / 2; origin.y: rays.height / 2; angle: index * 30 }
            }
        }
    }

    Rectangle {
        id: disc
        anchors.centerIn: parent
        width: sun.size * 0.95
        height: width
        radius: width / 2
        color: sun.gold

        Rectangle {   // a softer core
            anchors.centerIn: parent
            width: parent.width * 0.7
            height: width
            radius: width / 2
            color: Qt.lighter(sun.gold, 1.15)
        }
    }

    // Clouds: [x, y, width] as parts of the item, puffs of circles.
    Repeater {
        model: [[0.02, 0.66, 0.34], [0.66, 0.12, 0.26]]
        Item {
            id: cloud
            required property var modelData
            x: sun.width * modelData[0]
            y: sun.height * modelData[1]
            width: sun.width * modelData[2]
            height: width * 0.45
            Rectangle { x: 0; y: cloud.height * 0.35; width: cloud.width; height: cloud.height * 0.65; radius: height / 2; color: Qt.alpha(Theme.fgBright, 0.85) }
            Rectangle { x: cloud.width * 0.2; y: 0; width: cloud.height * 0.9; height: width; radius: width / 2; color: Qt.alpha(Theme.fgBright, 0.85) }
            Rectangle { x: cloud.width * 0.48; y: cloud.height * 0.15; width: cloud.height * 0.75; height: width; radius: width / 2; color: Qt.alpha(Theme.fgBright, 0.85) }
        }
    }
}
