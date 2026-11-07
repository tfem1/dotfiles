import QtQuick

// The concave corner joining the workspace "notch" to the top of the bar:
// a square filled with `color`, minus a quarter circle. `flipped` mirrors it
// for the right side of the notch.
Canvas {
    id: corner

    property color color: "black"
    property bool flipped: false

    implicitWidth: 14
    implicitHeight: 14
    onColorChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = corner.color;
        ctx.beginPath();
        if (!corner.flipped) {
            // Fills the top-right area outside a circle centered bottom-left.
            ctx.moveTo(width, 0);
            ctx.lineTo(width, height);
            ctx.arc(0, height, width, 0, -Math.PI / 2, true);
        } else {
            ctx.moveTo(0, 0);
            ctx.lineTo(0, height);
            ctx.arc(width, height, width, Math.PI, -Math.PI / 2, false);
        }
        ctx.closePath();
        ctx.fill();
    }
}
