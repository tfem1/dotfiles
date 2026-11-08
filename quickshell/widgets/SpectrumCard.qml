pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The audio widget: cava's bars in the accent color, each with a cap in the
// second color, and the device the sound goes to.
WidgetCard {
    id: card

    property var levels: []          // 0 to 1, from cava
    property string device: ""

    title: "Audio spectrum"

    Column {
        width: parent.width
        spacing: 12

        Row {
            id: bars
            height: 64
            spacing: 4

            Repeater {
                model: card.levels.length

                Item {
                    id: bar
                    required property int index
                    readonly property real level: card.levels[index] || 0

                    width: (card.width - 32 - bars.spacing * (card.levels.length - 1)) / Math.max(1, card.levels.length)
                    height: bars.height

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(3, bar.level * (bars.height - 5))
                        radius: Math.min(3, width / 2)
                        color: Qt.alpha(Theme.accent, 0.85)
                        Behavior on height { NumberAnimation { duration: Theme.animations ? 60 : 0 } }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: parent.radius
                            y: -5
                            color: Theme.accent2
                        }
                    }
                }
            }
        }

        Row {
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "speaker"
                color: Theme.subtle
                size: 15
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: card.width - 32 - 23
                text: card.device || "No output device"
                small: true
            }
        }
    }
}
