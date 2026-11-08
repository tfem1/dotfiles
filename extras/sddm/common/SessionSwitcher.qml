import QtQuick

// The session to start (Hyprland, or any other installed): a chip with its
// name; a click moves to the next one. Starts on the last one used.
Rectangle {
    id: chip

    property int currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property string sessionName: names.count > 0 && names.itemAt(currentIndex)
        ? names.itemAt(currentIndex).sessionName : ""

    implicitWidth: row.implicitWidth + 30
    implicitHeight: 38
    radius: height / 2
    visible: names.count > 0
    color: hover.hovered ? config.surface : Qt.alpha(config.bgAlt, 0.92)
    Behavior on color { ColorAnimation { duration: 150 } }

    // The names, read from the model once.
    Item {
        visible: false

        Repeater {
            id: names
            model: sessionModel

            Item {
                required property string name
                readonly property string sessionName: name
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "computer"
            color: config.accent
            size: 18
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.sessionName
            color: config.fg
            font.family: config.font
            font.pixelSize: 15
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: names.count > 1
            name: "chevron_right"
            color: config.subtle
            size: 16
        }
    }

    HoverHandler {
        id: hover
        cursorShape: names.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        onTapped: if (names.count > 1) chip.currentIndex = (chip.currentIndex + 1) % names.count
    }
}
