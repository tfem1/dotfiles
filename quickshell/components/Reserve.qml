import QtQuick
import Quickshell
import Quickshell.Wayland

// An invisible strip that keeps `size` pixels free along a screen edge, so
// windows are not placed under the bar or the dock. The bar and the dock
// themselves ignore what the others reserve (ExclusionMode.Ignore): they
// always span the whole screen edge, whichever is created first, and a dock
// on the left never pushes the top bar aside.
PanelWindow {
    id: reserve

    property string edge: "top"   // top | bottom | left | right
    property int size: 0

    anchors {
        top: reserve.edge !== "bottom"
        bottom: reserve.edge !== "top"
        left: reserve.edge !== "right"
        right: reserve.edge !== "left"
    }
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: size
    mask: Region {}   // takes no clicks
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desktop-reserve"   // not "shell-": never blurred
}
