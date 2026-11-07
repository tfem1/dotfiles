import QtQuick
import "../theme"
import "library.js" as Library

// The wallpaper itself, cropped to fill; a new one fades in over the old.
// The theme background shows while there is none.
Rectangle {
    id: backdrop

    property string path: ""

    function show() {
        incoming.source = Library.fileUrl(path);
        if (!path)
            shown.source = "";
    }

    color: Theme.bgAlt
    onPathChanged: show()
    Component.onCompleted: show()

    Image {
        id: shown
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        // Once it has the new image, the fading copy is dropped.
        onStatusChanged: {
            if (status === Image.Ready && String(source) === String(incoming.source)) {
                incoming.source = "";
                incoming.opacity = 0;
            }
        }
    }

    Image {
        id: incoming
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        opacity: 0
        onStatusChanged: if (status === Image.Ready) fade.restart()
    }

    NumberAnimation {
        id: fade
        target: incoming
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.duration * 3
        onFinished: shown.source = incoming.source
    }
}
