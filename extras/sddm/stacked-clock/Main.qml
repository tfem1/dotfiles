import QtQuick
import "common"

// Login screen "Stacked clock": the whole wallpaper, the date at the top
// left and a large clock, hours stacked over minutes in the accent color.
// Any key or a click brings the sign-in card; Escape (or 30 s without
// typing) goes back to the clock. The password field keeps the keyboard
// all along, so the first letter typed on the clock is already in it.
// Colors, font and wallpaper come from theme.conf (`tfem sddm install`).
Rectangle {
    id: root

    property date now: new Date()
    property bool signingIn: false
    property bool busy: false
    property string error: ""
    readonly property real unit: Math.max(0.7, Math.min(1.4, height / 1080))

    function open() {
        signingIn = true;
        idle.restart();
        password.focusInput();
    }

    function close() {
        signingIn = false;
        password.clear();
        error = "";
        password.focusInput();
    }

    function login() {
        if (!users.userName || busy)
            return;
        busy = true;
        error = "";
        sddm.login(users.userName, password.text, session.currentIndex);
    }

    width: 1920
    height: 1080
    color: config.bg
    Component.onCompleted: password.focusInput()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Back to the clock when nothing is typed for a while.
    Timer {
        id: idle
        interval: 30000
        onTriggered: if (!password.text) root.close()
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.busy = false;
            root.error = "Wrong password, try again";
            password.clear();
            password.failed = true;
            shake.restart();
            password.focusInput();
        }
        function onLoginSucceeded() {
            root.busy = false;
        }
    }

    Image {
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
    }
    // A plain veil (no gradient) keeps the clock readable on any picture.
    Rectangle {
        anchors.fill: parent
        color: config.bg
        opacity: root.signingIn ? 0.55 : 0.28
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    Text {
        x: 72 * root.unit
        y: 64 * root.unit
        text: root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM")
        color: config.fgBright
        font.family: config.font
        font.pixelSize: 30 * root.unit
        font.weight: Font.DemiBold
    }

    Column {
        id: clock
        x: 64 * root.unit
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 30 * root.unit
        spacing: -90 * root.unit

        Text {
            text: Qt.formatTime(root.now, "HH")
            color: config.accent
            font.family: config.font
            font.pixelSize: 300 * root.unit
            font.weight: Font.Bold
        }
        Text {
            text: Qt.formatTime(root.now, "mm")
            color: config.fgBright
            font.family: config.font
            font.pixelSize: 300 * root.unit
            font.weight: Font.Bold
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 56 * root.unit
        visible: !root.signingIn
        text: "Press any key to sign in"
        color: config.fgBright
        font.family: config.font
        font.pixelSize: 18 * root.unit
        opacity: 0.85

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: !root.signingIn
            NumberAnimation { to: 0.35; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.85; duration: 1400; easing.type: Easing.InOutSine }
        }
    }

    // The sign-in card, on the right.
    Rectangle {
        id: card
        width: 440 * root.unit
        height: form.implicitHeight + 64 * root.unit
        anchors.verticalCenter: parent.verticalCenter
        x: root.signingIn ? parent.width - width - 96 * root.unit : parent.width + 20
        opacity: root.signingIn ? 1 : 0
        radius: 28
        color: Qt.alpha(config.bg, 0.86)
        border.width: 1
        border.color: Qt.alpha(config.fgBright, 0.10)
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 240 } }

        Column {
            id: form
            anchors.centerIn: parent
            width: parent.width - 64 * root.unit
            spacing: 18 * root.unit

            UserSwitcher {
                id: users
                width: parent.width
                avatarSize: 96 * root.unit
                onUserNameChanged: if (root.signingIn) password.focusInput()
            }

            Row {
                id: passwordRow
                width: parent.width
                spacing: 10

                PasswordField {
                    id: password
                    width: parent.width - signIn.width - parent.spacing
                    // Enter on the clock only opens the card.
                    onAccepted: root.signingIn ? root.login() : root.open()
                    onTextChanged: {
                        if (text && !root.signingIn)
                            root.open();
                        idle.restart();
                    }
                }
                Rectangle {
                    id: signIn
                    width: password.height
                    height: password.height
                    radius: width / 2
                    color: signInHover.hovered ? config.accent2 : config.accent
                    opacity: root.busy ? 0.6 : 1

                    Icon {
                        anchors.centerIn: parent
                        name: "chevron_right"
                        color: config.bg
                        size: 26
                    }
                    HoverHandler {
                        id: signInHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler { onTapped: root.login() }
                }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: passwordRow; property: "x"; to: -12; duration: 50 }
                    NumberAnimation { target: passwordRow; property: "x"; to: 12; duration: 70 }
                    NumberAnimation { target: passwordRow; property: "x"; to: -6; duration: 60 }
                    NumberAnimation { target: passwordRow; property: "x"; to: 0; duration: 50 }
                }
            }

            Text {
                width: parent.width
                height: 18 * root.unit
                horizontalAlignment: Text.AlignHCenter
                text: root.error
                color: config.red
                font.family: config.font
                font.pixelSize: 15 * root.unit
            }

            SessionSwitcher {
                id: session
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    PowerButtons {
        anchors.right: parent.right
        anchors.rightMargin: 64 * root.unit
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48 * root.unit
        size: 42
    }

    // A click on the clock opens the card. Keys the password field does not
    // take (Shift, arrows, Escape...) come up here: they open it too, and
    // Escape closes it.
    TapHandler {
        enabled: !root.signingIn
        onTapped: root.open()
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && root.signingIn)
            root.close();
        else if (!root.signingIn)
            root.open();
        event.accepted = true;
    }
}
