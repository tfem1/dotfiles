import QtQuick
import "../theme"
import "../components"

// The on-screen display: an icon, a level bar and the value in percent.
Rectangle {
    id: osd

    property string icon: "volume_up"
    property real value: 0.5
    property color tone: Theme.modules.audio
    property bool off: false

    implicitWidth: 300
    implicitHeight: 52
    radius: height / 2
    color: Theme.panel

    Row {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 14

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: osd.icon
            color: osd.off ? Theme.muted : osd.tone
            size: 22
        }

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 22 - percent.width - parent.spacing * 2
            height: 8
            radius: 4
            color: Theme.surface

            Rectangle {
                width: Math.max(height, track.width * Math.max(0, Math.min(1, osd.value)))
                height: parent.height
                radius: parent.radius
                color: osd.off ? Theme.muted : osd.tone
                Behavior on width { NumberAnimation { duration: Theme.duration } }
            }
        }

        Label {
            id: percent
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(osd.value * 100)
            font.weight: Font.DemiBold
        }
    }
}
