import QtQuick
import "../theme"
import "../components"
import "../wallpaper/library.js" as Library

// What the lock screen shows, like the "stacked clock" login screen: the
// wallpaper under a veil, the date, hours over minutes in the accent color.
// Typing brings the card (the password field has the keyboard all along);
// Escape clears it. Plain properties: shown with sample data by the preview.
Rectangle {
    id: screen

    property string user: ""
    property string password: ""
    property string failure: ""
    property bool checking: false
    property string layout: ""            // keyboard layout, e.g. "US"
    property date now: new Date()
    property bool live: true              // the clock ticks (off in previews)
    property url background: Library.fileUrl(Theme.wallpaper)
    signal typed(string text)
    signal submitted

    readonly property bool asking: password !== "" || failure !== "" || checking
    readonly property real unit: Math.max(0.6, Math.min(1.4, height / 1080))

    color: Theme.bg
    onFailureChanged: if (failure) shake.restart()

    Timer {
        interval: 1000
        running: screen.live
        repeat: true
        onTriggered: screen.now = new Date()
    }

    Image {
        anchors.fill: parent
        source: screen.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    // A plain veil (no gradient) keeps the clock readable on any picture.
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: screen.asking ? 0.55 : 0.3
        Behavior on opacity { NumberAnimation { duration: Theme.duration * 2 } }
    }

    Label {
        x: 72 * screen.unit
        y: 64 * screen.unit
        text: screen.now.toLocaleDateString(Qt.locale(), "dddd d MMMM")
        color: Theme.fgBright
        font.pixelSize: 30 * screen.unit
        font.weight: Font.DemiBold
    }

    Column {
        x: 64 * screen.unit
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 30 * screen.unit
        spacing: -90 * screen.unit

        Label {
            text: Qt.formatTime(screen.now, "HH")
            color: Theme.accent
            font.pixelSize: 300 * screen.unit
            font.weight: Font.Bold
        }
        Label {
            text: Qt.formatTime(screen.now, "mm")
            color: Theme.fgBright
            font.pixelSize: 300 * screen.unit
            font.weight: Font.Bold
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 56 * screen.unit
        visible: !screen.asking
        text: "Type your password to unlock"
        color: Theme.fgBright
        opacity: 0.8
        font.pixelSize: 18 * screen.unit
    }

    // The card: who is locked, the password, what went wrong.
    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: 110 * screen.unit
        anchors.verticalCenter: parent.verticalCenter
        width: 340
        height: column.implicitHeight + 56
        radius: Theme.radius + 10
        color: Qt.alpha(Theme.bgAlt, 0.92)
        border.width: 1
        border.color: Theme.surface
        opacity: screen.asking ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.duration } }

        SequentialAnimation on anchors.rightMargin {
            id: shake
            running: false
            NumberAnimation { to: 110 * screen.unit + 14; duration: 50 }
            NumberAnimation { to: 110 * screen.unit - 14; duration: 80 }
            NumberAnimation { to: 110 * screen.unit + 8; duration: 70 }
            NumberAnimation { to: 110 * screen.unit; duration: 60 }
        }

        Column {
            id: column
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 14

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                height: 64
                radius: 32
                color: Theme.accent
                Label {
                    anchors.centerIn: parent
                    text: (screen.user || "?").charAt(0).toUpperCase()
                    color: Theme.bg
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: screen.user
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: parent.width
                height: 44
                radius: height / 2
                color: Theme.bg
                border.width: 1
                border.color: screen.failure ? Theme.red : Theme.accent

                TextInput {
                    id: field
                    objectName: "password"
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    text: screen.password
                    color: Theme.fgBright
                    font.family: Theme.fontSans
                    font.pixelSize: Math.round(Theme.fontPixels * 1.05)
                    selectionColor: Theme.accent
                    readOnly: screen.checking
                    focus: true
                    Component.onCompleted: forceActiveFocus()
                    onTextEdited: screen.typed(text)
                    Keys.onReturnPressed: screen.submitted()
                    Keys.onEnterPressed: screen.submitted()
                    Keys.onEscapePressed: screen.typed("")
                }
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text === ""
                    text: screen.checking ? "Checking…" : "Password"
                    small: true
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: screen.failure || (screen.layout ? "Keyboard: " + screen.layout : " ")
                color: screen.failure ? Theme.red : Theme.subtle
                small: true
            }
        }
    }
}
