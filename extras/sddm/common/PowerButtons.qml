import QtQuick

// Suspend, restart and shut down: round buttons, each shown only when the
// machine allows it; the name of the action shows under the pointer.
Row {
    id: buttons

    property int size: 46

    spacing: 14

    component RoundButton: Item {
        id: button

        property string icon: ""
        property string label: ""
        signal clicked

        width: buttons.size
        height: buttons.size

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: hover.hovered ? config.accent : Qt.alpha(config.bgAlt, 0.92)
            border.width: hover.hovered ? 0 : 1
            border.color: config.surface
            Behavior on color { ColorAnimation { duration: 150 } }

            Icon {
                anchors.centerIn: parent
                name: button.icon
                color: hover.hovered ? config.bg : config.fg
                size: 22
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 6
            visible: hover.hovered
            text: button.label
            color: config.fgBright
            font.family: config.font
            font.pixelSize: 13
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler { onTapped: button.clicked() }
    }

    RoundButton {
        visible: sddm.canSuspend
        icon: "bedtime"
        label: "Suspend"
        onClicked: sddm.suspend()
    }
    RoundButton {
        visible: sddm.canReboot
        icon: "restart_alt"
        label: "Restart"
        onClicked: sddm.reboot()
    }
    RoundButton {
        visible: sddm.canPowerOff
        icon: "power_settings_new"
        label: "Shut down"
        onClicked: sddm.powerOff()
    }
}
