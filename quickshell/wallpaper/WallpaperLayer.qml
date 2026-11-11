import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// The wallpaper on every screen, under the windows: drawn by the shell, so
// no other program has to run for it. Follows theme.json live.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "desktop-wallpaper"   // not "shell-": never blurred

        Backdrop {
            anchors.fill: parent
            path: Theme.wallpaper
        }
    }
}
