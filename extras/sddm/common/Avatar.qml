import QtQuick

// The user's picture as SDDM finds it (~/.face.icon, AccountsService), cut
// round; the first letter of the name while there is none. Drawn with a
// Canvas: no shader needed, so it looks the same on any graphics.
Item {
    id: avatar

    property string source: ""
    property string name: ""
    property int size: 88
    readonly property string url: source.startsWith("/") ? "file://" + source : source

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        visible: !picture.ready
        radius: width / 2
        color: config.accent

        Text {
            anchors.centerIn: parent
            text: (avatar.name || "?").charAt(0).toUpperCase()
            color: config.bg
            font.family: config.font
            font.pixelSize: Math.round(avatar.size * 0.42)
            font.weight: Font.DemiBold
        }
    }

    Canvas {
        id: picture

        property bool ready: false

        anchors.fill: parent
        Component.onCompleted: if (avatar.url) loadImage(avatar.url)
        onImageLoaded: {
            ready = isImageLoaded(avatar.url);
            requestPaint();
        }
        onPaint: {
            const context = getContext("2d");
            context.reset();
            if (!ready)
                return;
            context.beginPath();
            context.arc(width / 2, height / 2, width / 2, 0, 2 * Math.PI);
            context.closePath();
            context.clip();
            context.drawImage(avatar.url, 0, 0, width, height);
        }
    }

    // A thin ring in the accent color around the picture.
    Rectangle {
        anchors.fill: parent
        visible: picture.ready
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: config.accent
    }
}
