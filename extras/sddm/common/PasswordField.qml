import QtQuick

// The password: dots, or the text while the eye is on. Enter signs in; the
// placeholder warns when Caps Lock is on; the border turns red after a
// wrong password until something is typed.
Rectangle {
    id: field

    property alias text: input.text
    property bool reveal: false
    property bool failed: false
    readonly property bool capsLock: typeof keyboard !== "undefined" && keyboard !== null && keyboard.capsLock
    signal accepted

    function clear() {
        input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 340
    implicitHeight: 50
    radius: height / 2
    color: Qt.alpha(config.bgAlt, 0.92)
    border.width: input.activeFocus || failed ? 2 : 1
    border.color: failed ? config.red : input.activeFocus ? config.accent : config.surface
    Behavior on border.color { ColorAnimation { duration: 150 } }

    TextInput {
        id: input
        objectName: "password"   // found by the tests
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.right: eye.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        echoMode: field.reveal ? TextInput.Normal : TextInput.Password
        passwordCharacter: "●"
        color: config.fgBright
        selectionColor: config.accent
        selectedTextColor: config.bg
        font.family: config.font
        font.pixelSize: 17
        clip: true
        focus: true
        onAccepted: field.accepted()
        onTextChanged: if (text) field.failed = false
    }

    Text {
        anchors.fill: input
        visible: !input.text
        verticalAlignment: Text.AlignVCenter
        text: field.capsLock ? "Password · Caps Lock is on" : "Password"
        color: field.capsLock ? config.accent : config.subtle
        font.family: config.font
        font.pixelSize: 17
        elide: Text.ElideRight
    }

    Icon {
        id: eye
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        name: field.reveal ? "visibility_off" : "visibility"
        color: eyeHover.hovered ? config.fgBright : config.subtle
        size: 20

        HoverHandler {
            id: eyeHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                field.reveal = !field.reveal;
                field.focusInput();
            }
        }
    }
}
