import QtQuick
import Quickshell
import "../components"

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

        Scope {
            id: perScreen
            required property var modelData

            Bar {
                id: bar
                modelData: perScreen.modelData
                autohide: root.autohide
                onStatusClicked: root.statusClicked()
                onClockClicked: root.clockClicked()
                onPowerClicked: root.powerClicked()
                onLogoClicked: root.logoClicked()
            }
            // Windows stay clear of the bar; with autohide they use the whole screen.
            Reserve {
                screen: perScreen.modelData
                edge: bar.edge
                size: root.autohide ? 0 : bar.thickness
            }
        }
    }
}
