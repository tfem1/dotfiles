import QtQuick
import "../theme"

// The same around the cover: a thin ring, and the part played as a wave
// along it, from the top, clockwise.
Canvas {
    id: ring

    property real progress: 0
    property color color: Theme.accent
    property color track: Qt.alpha(Theme.fg, 0.18)
    property bool moving: false
    property real phase: 0

    onProgressChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onColorChanged: requestPaint()

    NumberAnimation on phase {
        running: ring.moving && Theme.animations
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const c = width / 2, r = width / 2 - 6;
        ctx.lineWidth = 2;
        ctx.strokeStyle = track;
        ctx.beginPath();
        ctx.arc(c, c, r, 0, Math.PI * 2);
        ctx.stroke();
        const end = Math.max(0, Math.min(1, progress)) * Math.PI * 2;
        ctx.lineWidth = 3.5;
        ctx.lineCap = "round";
        ctx.strokeStyle = color;
        ctx.beginPath();
        for (let a = 0; a <= end; a += 0.01) {
            const wave = r + Math.sin(a * 18 - phase) * 3;
            ctx.lineTo(c + Math.sin(a) * wave, c - Math.cos(a) * wave);
        }
        ctx.stroke();
    }
}
