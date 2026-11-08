import QtQuick
import Quickshell

// One bar per screen, and what they share: autohide (SUPER + A).
Scope {
    id: root

    property bool autohide: false
    signal statusClicked   // the status icons of a bar were clicked
    signal clockClicked
    signal powerClicked
    signal logoClicked     // the distro logo: opens the Settings window

    function toggleAutohide() {
        autohide = !autohide;
    }

    Variants {
        model: Quickshell.screens

        Bar {
            autohide: root.autohide
            onStatusClicked: root.statusClicked()
            onClockClicked: root.clockClicked()
            onPowerClicked: root.powerClicked()
            onLogoClicked: root.logoClicked()
        }
    }
}
