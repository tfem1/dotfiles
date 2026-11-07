import QtQuick
import "../theme"

// Rounded search field with an icon and a placeholder. Arrow keys, Enter and
// Escape are passed on as signals, for the list shown under the field.
Rectangle {
    id: field

    property alias text: input.text
    property string placeholder: ""
    signal moveUp
    signal moveDown
    signal accepted
    signal cancelled

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: 48
    radius: height / 2
    color: Theme.surface

    Icon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        color: Theme.accent
        size: 20
    }

    TextInput {
        id: input
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        selectionColor: Theme.accent
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontPixels * 1.15
        focus: true
        Keys.onDownPressed: field.moveDown()
        Keys.onUpPressed: field.moveUp()
        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()
        Keys.onEscapePressed: field.cancelled()

        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: field.placeholder
            color: Theme.subtle
            font.pixelSize: input.font.pixelSize
        }
    }
}
