import QtQuick
import "../theme"
import "../components"

// Everything drawn in the bar, fed by plain properties so it can be shown
// with real data (Bar.qml) or sample data (tools/preview).
Rectangle {
    id: bar

    property var workspaces: []
    property bool hasMedia: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property real mediaProgress: 0
    property bool mediaPlaying: false
    property date now: new Date()
    property alias status: statusArea

    signal workspaceClicked(int id)
    signal mediaToggled
    signal rightClicked
    signal clockClicked
    signal powerClicked

    implicitHeight: 44
    color: Theme.panel

    Row {
        id: center
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        spacing: 8

        MediaChip {
            anchors.verticalCenter: parent.verticalCenter
            visible: bar.hasMedia
            title: bar.mediaTitle
            artist: bar.mediaArtist
            progress: bar.mediaProgress
            playing: bar.mediaPlaying
            onToggle: bar.mediaToggled()
        }

        // The "notch": workspaces hang from the top edge, rounded at the bottom.
        Row {
            height: parent.height

            NotchCorner { anchors.top: parent.top; color: Theme.bgAlt }
            Rectangle {
                height: parent.height - 4
                width: workspaceRow.implicitWidth + 20
                color: Theme.bgAlt
                bottomLeftRadius: 16
                bottomRightRadius: 16

                Workspaces {
                    id: workspaceRow
                    anchors.centerIn: parent
                    model: bar.workspaces
                    onClicked: id => bar.workspaceClicked(id)
                }
            }
            NotchCorner { anchors.top: parent.top; flipped: true; color: Theme.bgAlt }
        }

        ClockChip {
            anchors.verticalCenter: parent.verticalCenter
            now: bar.now
            onClicked: bar.clockClicked()
        }
    }

    StatusArea {
        id: statusArea
        anchors.right: power.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        onClicked: bar.rightClicked()
    }

    // Opens the power menu.
    Pill {
        id: power
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        padding: 9
        onClicked: bar.powerClicked()

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "power_settings_new"
            color: Theme.accent2
            size: 17
        }
    }
}
