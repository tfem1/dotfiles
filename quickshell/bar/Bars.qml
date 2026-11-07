import QtQuick
import Quickshell

// One bar per screen, and what they share: autohide (SUPER + A).
Scope {
    id: root

    property bool autohide: false
    signal statusClicked   // the status icons of a bar were clicked
    signal clockClicked

    function toggleAutohide() {
        autohide = !autohide;
    }

    Variants {
        model: Quickshell.screens

        Bar {
            autohide: root.autohide
            onStatusClicked: root.statusClicked()
            onClockClicked: root.clockClicked()
        }
    }
}
