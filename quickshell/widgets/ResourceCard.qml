import QtQuick
import "../theme"
import "../components"

// CPU, GPU, RAM or disk: a ring with the percentage, the name and a detail
// ("8 cores", "6.2 / 16 GB"), in one of the theme's colors.
WidgetCard {
    id: card

    property string name: ""
    property string detail: ""
    property real value: 0
    property color tint: Theme.accent

    implicitHeight: 84

    Row {
        spacing: 10
        y: -2

        RingProgress {
            width: 52
            height: 52
            value: card.value
            color: card.tint
            track: Qt.alpha(card.tint, 0.18)
            thickness: 5

            Label {
                anchors.centerIn: parent
                text: Math.round(card.value * 100) + "%"
                color: Theme.fgBright
                font.weight: Font.DemiBold
                font.pixelSize: Math.round(Theme.fontPixels * 0.92)
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: card.width - 32 - 62
            spacing: 2
            Label {
                width: parent.width
                text: card.name
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                text: card.detail
                small: true
            }
        }
    }
}
