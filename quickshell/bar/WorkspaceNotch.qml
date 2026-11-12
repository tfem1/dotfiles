import QtQuick
import "../theme"
import "../components"

// The workspaces in the "notch": they hang from the screen edge, rounded on
// the inner side, with concave corners joining the bar (top and bottom).
// Without the bar's background (`hanging` false), a plain pill.
Item {
    id: notch

    property string edge: "top"
    property bool vertical: false
    property bool hanging: true
    property var workspaces: []
    property int barWidth: 0
    property int barHeight: 0
    signal clicked(int id)

    width: notch.vertical ? notch.barWidth : notchBox.width + (corners.visible ? 28 : 0)
    height: notch.vertical ? notchBox.height : notch.barHeight

    Rectangle {
        id: notchBox
        readonly property int depth: notch.hanging ? 4 : 6     // space left on the open side
        x: !notch.vertical || !notch.hanging ? (parent.width - width) / 2 : notch.edge === "left" ? 0 : depth
        y: notch.vertical || !notch.hanging ? (parent.height - height) / 2 : notch.edge === "top" ? 0 : depth
        width: notch.vertical ? (notch.hanging ? notch.barWidth - depth : 36) : workspaceRow.implicitWidth + 20
        height: notch.vertical ? workspaceRow.implicitHeight + 20 : (notch.hanging ? notch.barHeight - depth : 32)
        color: Theme.bgAlt
        radius: notch.hanging ? 0 : Math.min(width, height) / 2
        topLeftRadius: !notch.hanging ? radius : notch.edge === "bottom" || notch.edge === "right" ? 16 : 0
        topRightRadius: !notch.hanging ? radius : notch.edge === "bottom" || notch.edge === "left" ? 16 : 0
        bottomLeftRadius: !notch.hanging ? radius : notch.edge === "top" || notch.edge === "right" ? 16 : 0
        bottomRightRadius: !notch.hanging ? radius : notch.edge === "top" || notch.edge === "left" ? 16 : 0

        Workspaces {
            id: workspaceRow
            anchors.centerIn: parent
            vertical: notch.vertical
            model: notch.workspaces
            onClicked: id => notch.clicked(id)
        }
    }

    // Concave corners, for a bar at the top or bottom.
    Item {
        id: corners
        visible: notch.hanging && !notch.vertical
        anchors.fill: parent
        transform: Scale { origin.y: corners.height / 2; yScale: notch.edge === "bottom" ? -1 : 1 }

        NotchCorner { x: notchBox.x - width; color: Theme.bgAlt }
        NotchCorner { x: notchBox.x + notchBox.width; flipped: true; color: Theme.bgAlt }
    }
}
