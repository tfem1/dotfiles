import QtQuick

// A thin circular progress ring (0 to 1), drawn around its children.
Item {
    id: ring

    property real value: 0
    property color color: "white"
    property color track: "transparent"
    property real thickness: 2.5
    default property alias content: inside.data

    implicitWidth: 28
    implicitHeight: 28
    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            const center = width / 2;
            const radius = center - ring.thickness;
            ctx.reset();
            ctx.lineWidth = ring.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = ring.track;
            ctx.beginPath();
            ctx.arc(center, center, radius, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.strokeStyle = ring.color;
            ctx.beginPath();
            ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(0, Math.min(1, ring.value)));
            ctx.stroke();
        }
    }

    Item {
        id: inside
        anchors.fill: parent
    }
}
