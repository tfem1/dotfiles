import QtQuick
import "../theme"
import "library.js" as Library

// The wallpaper itself, cropped to fill. A new one slides in from the right
// over the old one; the very first is shown at once. The theme background
// shows while there is none.
Rectangle {
    id: backdrop

    property string path: ""

    function show() {
        incoming.source = Library.fileUrl(path);
        if (!path)
            shown.source = "";
    }

    color: Theme.bgAlt
    clip: true
    onPathChanged: show()
    Component.onCompleted: show()

    Image {
        id: shown
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        // Once it has the new image, the sliding copy is dropped.
        onStatusChanged: {
            if (status === Image.Ready && String(source) === String(incoming.source)) {
                incoming.source = "";
                incoming.x = backdrop.width;
            }
        }
    }

    Image {
        id: incoming
        x: backdrop.width   // waits off screen, on the right
        width: backdrop.width
        height: backdrop.height
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        onStatusChanged: {
            if (status !== Image.Ready)
                return;
            if (shown.status === Image.Ready)
                slide.restart();
            else
                shown.source = source;   // nothing to slide over
        }
    }

    NumberAnimation {
        id: slide
        target: incoming
        property: "x"
        from: backdrop.width
        to: 0
        duration: Theme.duration * 4
        easing.type: Easing.OutCubic
        onFinished: shown.source = incoming.source
    }
}
