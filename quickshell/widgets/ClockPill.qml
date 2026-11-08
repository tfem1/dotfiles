import QtQuick
import "../theme"
import "../components"
import "resources.js" as Resources

// The clock widget: a pill in the accent color, the date then the time.
Rectangle {
    id: pill

    property date now: new Date()
    readonly property var parts: Resources.clockParts(now)

    implicitWidth: row.implicitWidth + 44
    implicitHeight: 62
    radius: height / 2
    color: Theme.accent

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 14

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: pill.parts.date
            color: Theme.bg
            font.pixelSize: Math.round(Theme.fontPixels * 1.15)
            font.weight: Font.DemiBold
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 22
            radius: 1
            color: Qt.alpha(Theme.bg, 0.35)
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: pill.parts.time
            color: Theme.bg
            font.pixelSize: Math.round(Theme.fontPixels * 2.2)
            font.weight: Font.Bold
        }
    }
}
