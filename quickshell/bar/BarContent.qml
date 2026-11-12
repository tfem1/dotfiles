import QtQuick
import "../theme"
import "../components"
import "../services"

// Everything drawn in the bar, fed by plain properties so it can be shown
// with real data (Bar.qml) or sample data (tools/preview). `edge`: the side
// of the screen it stands on; on the left or right, everything is stacked.
// `transparent`: no background, only the pills show.
Rectangle {
    id: bar

    property string edge: "top"         // top | bottom | left | right
    property bool transparent: false
    property var workspaces: []
    property bool hasMedia: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property real mediaProgress: 0
    property bool mediaPlaying: false
    property date now: new Date()
    property string distro: ""      // os-release ID, for the logo at the start
    property var status: ({})       // see StatusArea
    readonly property bool vertical: edge === "left" || edge === "right"
    // The notch hangs from the screen edge, unless the bar has no background.
    readonly property bool notch: !transparent

    signal workspaceClicked(int id)
    signal mediaToggled
    signal rightClicked
    signal clockClicked
    signal powerClicked
    signal logoClicked

    implicitHeight: vertical ? 600 : 44
    implicitWidth: vertical ? 52 : 1200
    color: transparent ? "transparent" : Theme.panel

    DistroButton {
        id: logo
        x: bar.vertical ? (bar.width - width) / 2 : 10
        y: bar.vertical ? 10 : (bar.height - height) / 2
        vertical: bar.vertical
        distro: bar.distro
        onClicked: bar.logoClicked()
    }

    Grid {
        id: center
        anchors.centerIn: parent
        columns: bar.vertical ? 1 : -1
        rows: bar.vertical ? -1 : 1
        spacing: 8
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        MediaChip {
            visible: bar.hasMedia
            vertical: bar.vertical
            title: bar.mediaTitle
            artist: bar.mediaArtist
            progress: bar.mediaProgress
            playing: bar.mediaPlaying
            onToggle: bar.mediaToggled()
        }

        // The "notch": workspaces hang from the screen edge, rounded on the
        // inner side, with concave corners joining the bar (top and bottom).
        Item {
            width: bar.vertical ? bar.width : notchBox.width + (corners.visible ? 28 : 0)
            height: bar.vertical ? notchBox.height : bar.height

            Rectangle {
                id: notchBox
                readonly property int depth: bar.notch ? 4 : 6     // space left on the open side
                x: !bar.vertical || !bar.notch ? (parent.width - width) / 2 : bar.edge === "left" ? 0 : depth
                y: bar.vertical || !bar.notch ? (parent.height - height) / 2 : bar.edge === "top" ? 0 : depth
                width: bar.vertical ? (bar.notch ? bar.width - depth : 36) : workspaceRow.implicitWidth + 20
                height: bar.vertical ? workspaceRow.implicitHeight + 20 : (bar.notch ? bar.height - depth : 32)
                color: Theme.bgAlt
                radius: bar.notch ? 0 : Math.min(width, height) / 2
                topLeftRadius: !bar.notch ? radius : bar.edge === "bottom" || bar.edge === "right" ? 16 : 0
                topRightRadius: !bar.notch ? radius : bar.edge === "bottom" || bar.edge === "left" ? 16 : 0
                bottomLeftRadius: !bar.notch ? radius : bar.edge === "top" || bar.edge === "right" ? 16 : 0
                bottomRightRadius: !bar.notch ? radius : bar.edge === "top" || bar.edge === "left" ? 16 : 0

                Workspaces {
                    id: workspaceRow
                    anchors.centerIn: parent
                    vertical: bar.vertical
                    model: bar.workspaces
                    onClicked: id => bar.workspaceClicked(id)
                }
            }

            // Concave corners, for a bar at the top or bottom.
            Item {
                id: corners
                visible: bar.notch && !bar.vertical
                anchors.fill: parent
                transform: Scale { origin.y: corners.height / 2; yScale: bar.edge === "bottom" ? -1 : 1 }

                NotchCorner { x: notchBox.x - width; color: Theme.bgAlt }
                NotchCorner { x: notchBox.x + notchBox.width; flipped: true; color: Theme.bgAlt }
            }
        }

        ClockChip {
            vertical: bar.vertical
            now: bar.now
            onClicked: bar.clockClicked()
        }
    }

    StatusArea {
        id: statusArea
        x: bar.vertical ? (bar.width - width) / 2 : power.x - width - 6
        y: bar.vertical ? power.y - height - 6 : (bar.height - height) / 2
        vertical: bar.vertical
        status: bar.status
        onClicked: bar.rightClicked()
        onUpdatesClicked: Updates.install()
    }

    // Opens the power menu.
    Pill {
        id: power
        x: bar.vertical ? (bar.width - width) / 2 : bar.width - width - 10
        y: bar.vertical ? bar.height - height - 10 : (bar.height - height) / 2
        vertical: bar.vertical
        padding: 9
        onClicked: bar.powerClicked()

        Icon {
            name: "power_settings_new"
            color: Theme.accent2
            size: 17
        }
    }
}
