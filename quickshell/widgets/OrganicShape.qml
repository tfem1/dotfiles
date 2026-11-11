import QtQuick
import "shapes.js" as Shapes

// A soft organic shape (see shapes.js), filled and outlined. Drawn once,
// and again only when its size, kind or colors change.
Canvas {
    id: shape

    property string kind: "cookie"     // cookie | flower | clover | circle
    property color fill: "black"
    property color stroke: "transparent"
    property real strokeWidth: 1.5

    onKindChanged: requestPaint()
    onFillChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const inset = strokeWidth;
        const points = Shapes.outline(kind, width - inset * 2, height - inset * 2, 180);
        ctx.beginPath();
        points.forEach((point, index) => {
            if (index === 0)
                ctx.moveTo(point[0] + inset, point[1] + inset);
            else
                ctx.lineTo(point[0] + inset, point[1] + inset);
        });
        ctx.closePath();
        ctx.fillStyle = fill;
        ctx.fill();
        if (stroke.a > 0) {
            ctx.lineWidth = strokeWidth;
            ctx.strokeStyle = stroke;
            ctx.stroke();
        }
    }
}
