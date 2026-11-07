pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// One line of the cheatsheet: key caps on the left, the action on the right.
// `keys` is a list of alternatives, each a list of key names; two are shown.
Item {
    id: row

    property var keys: []
    property string description: ""
    property int keysWidth: 176

    implicitWidth: keysWidth + 290
    implicitHeight: 30

    Row {
        id: caps
        anchors.verticalCenter: parent.verticalCenter
        width: row.keysWidth
        spacing: 4
        clip: true

        Repeater {
            model: row.keys.slice(0, 2)

            Row {
                id: alternative
                required property var modelData
                required property int index
                spacing: 4

                Label {
                    visible: alternative.index > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/"
                    small: true
                }
                Repeater {
                    model: alternative.modelData

                    Rectangle {
                        id: keyCap
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(24, cap.implicitWidth + 12)
                        height: 22
                        radius: 6
                        color: Theme.surface

                        Label {
                            id: cap
                            anchors.centerIn: parent
                            text: keyCap.modelData
                            mono: true
                            small: true
                            color: Theme.fgBright
                        }
                    }
                }
            }
        }
    }

    Label {
        anchors.left: caps.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: row.description
    }
}
