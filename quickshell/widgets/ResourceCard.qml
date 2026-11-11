import QtQuick
import "../theme"
import "../components"

// CPU, GPU, RAM or disk, in an organic shape (`kind`, see shapes.js), a
// little see-through: a ring with the percentage, then the name and a
// detail ("8 cores", "6.2 / 16 GB"), in one of the theme's colors.
Item {
    id: card

    property string kind: "cookie"
    property string name: ""
    property string detail: ""
    property real value: 0
    property color tint: Theme.accent

    implicitWidth: 170
    implicitHeight: width

    OrganicShape {
        anchors.fill: parent
        kind: card.kind
        fill: Qt.alpha(Theme.bg, 0.62)
        stroke: Qt.alpha(card.tint, 0.45)
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        RingProgress {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(card.width * 0.36)
            height: width
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
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.name
            color: Theme.fgBright
            font.weight: Font.DemiBold
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, card.width * 0.62)
            horizontalAlignment: Text.AlignHCenter
            text: card.detail
            small: true
        }
    }
}
