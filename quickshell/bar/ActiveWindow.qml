import QtQuick
import "../components"

// The focused window: app id on a small line, title below.
Column {
    property string appId: ""
    property string title: ""

    Label {
        width: parent.width
        text: parent.appId || "Desktop"
        small: true
    }
    Label {
        width: parent.width
        text: parent.title || "Workspace"
        font.weight: Font.Medium
    }
}
