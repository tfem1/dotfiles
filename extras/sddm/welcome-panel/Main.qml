import QtQuick
import QtQuick.Effects
import "common"

// Login screen "Welcome panel": the wallpaper, and on its left a frosted
// panel with a greeting, the time and date, who signs in, the password and
// the session; suspend, restart and shut down at the bottom. Colors, font
// and wallpaper come from theme.conf, written by `tfem sddm install`.
Rectangle {
    id: root

    property date now: new Date()
    property bool busy: false
    property string error: ""
    readonly property real unit: Math.max(0.7, Math.min(1.4, height / 1080))

    function login() {
        if (!users.userName || busy)
            return;
        busy = true;
        error = "";
        sddm.login(users.userName, password.text, session.currentIndex);
    }

    function greeting() {
        const hour = now.getHours();
        return hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
    }

    width: 1920
    height: 1080
    color: config.bg

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
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
        id: wallpaper
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
    }

    Item {
        id: panel
        width: Math.min(parent.width * 0.38, 600 * root.unit)
        height: parent.height
        clip: true

        // The wallpaper under the panel, blurred. Without shader support
        // the panel stays a plain tinted glass, as readable.
        MultiEffect {
            width: root.width
            height: root.height
            visible: wallpaper.status === Image.Ready
            source: wallpaper
            blurEnabled: true
            blur: 1.0
            blurMax: 64
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(config.bg, 0.74)
        }
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Qt.alpha(config.fgBright, 0.10)
        }

        Column {
            x: 56 * root.unit
            y: 64 * root.unit
            width: parent.width - 2 * x
            spacing: 4 * root.unit

            Text {
                text: root.greeting()
                color: config.subtle
                font.family: config.font
                font.pixelSize: 24 * root.unit
            }
            Text {
                text: Qt.formatTime(root.now, "HH:mm")
                color: config.fgBright
                font.family: config.font
                font.pixelSize: 108 * root.unit
                font.weight: Font.Light
            }
            Text {
                text: root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM")
                color: config.accent
                font.family: config.font
                font.pixelSize: 22 * root.unit
                font.weight: Font.DemiBold
            }
        }

        Column {
            id: form
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 90 * root.unit
            width: Math.min(parent.width - 112 * root.unit, 380 * root.unit)
            spacing: 18 * root.unit

            UserSwitcher {
                id: users
                width: parent.width
                avatarSize: 104 * root.unit
                onUserNameChanged: password.focusInput()
            }

            Row {
                id: passwordRow
                width: parent.width
                spacing: 10

                PasswordField {
                    id: password
                    width: parent.width - signIn.width - parent.spacing
                    onAccepted: root.login()
                    Component.onCompleted: focusInput()
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

                // A wrong password shakes the field.
                SequentialAnimation {
                    id: shake
                    loops: 1
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

        PowerButtons {
            anchors.left: parent.left
            anchors.leftMargin: 56 * root.unit
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 56 * root.unit
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 56 * root.unit
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 68 * root.unit
            text: sddm.hostName
            color: config.subtle
            font.family: config.font
            font.pixelSize: 14 * root.unit
        }
    }

    Keys.onEscapePressed: {
        password.clear();
        root.error = "";
    }
}
