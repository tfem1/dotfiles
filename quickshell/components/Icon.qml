import QtQuick
import "icons.js" as Icons

// A Material Symbols icon drawn in any color (path data from icons.js).
Image {
    property string name: ""
    property color color: "white"
    property int size: 18

    width: size
    height: size
    sourceSize: Qt.size(size * 2, size * 2)
    source: name ? Icons.source(name, color.toString()) : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
}
