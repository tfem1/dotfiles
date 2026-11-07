import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Full-screen layer for the launcher-like panels: dims the desktop, takes the
// keyboard, and asks to be closed when the dimmed part is clicked. The panel
// itself goes inside, as a child.
PanelWindow {
    id: overlay

    required property string name
    signal dismissed

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Qt.alpha(Theme.bgAlt, 0.45)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "shell-" + name

    MouseArea {
        anchors.fill: parent
        onClicked: overlay.dismissed()
    }
}
