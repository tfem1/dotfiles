import QtQuick
import "../theme"
import "../components"

// Everything drawn in the bar, fed by plain properties so it can be shown
// with real data (Bar.qml) or sample data (tools/preview).
Rectangle {
    id: bar

    property string appId: ""
    property string title: ""
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
    signal leftClicked
    signal rightClicked

    implicitHeight: 44
    color: Theme.panel

    ActiveWindow {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, center.x - 36)
        appId: bar.appId
        title: bar.title
        TapHandler { onTapped: bar.leftClicked() }
    }

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
        }
    }

    StatusArea {
        id: statusArea
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        onClicked: bar.rightClicked()
    }
}
