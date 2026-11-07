import QtQuick
import "../theme"

// Text in the theme font and color; `small` for secondary lines.
Text {
    property bool small: false
    property bool mono: false

    color: small ? Theme.subtle : Theme.fg
    font.family: mono ? Theme.fontMono : Theme.fontSans
    font.pixelSize: Math.round(Theme.fontPixels * (small ? 0.82 : 1))
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
