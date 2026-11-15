import QtQuick
import "../theme"

// How far the song is: the part played is a wave, the rest a thin straight
// line, a dot at its end. The wave moves while `moving` (playing).
Canvas {
    id: line

    property real progress: 0
    property color color: Theme.accent
    property color track: Qt.alpha(Theme.fg, 0.25)
    property bool moving: false
    property real phase: 0

    implicitHeight: 14
    onProgressChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onColorChanged: requestPaint()

    NumberAnimation on phase {
        running: line.moving && Theme.animations
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const mid = height / 2, end = Math.max(0, Math.min(1, progress)) * width;
        ctx.lineCap = "round";
        ctx.lineWidth = 3;
        ctx.strokeStyle = color;
        ctx.beginPath();
        for (let x = 2; x <= end; x += 1)
            ctx.lineTo(x, mid + Math.sin(x / 14 * Math.PI * 2 - phase) * 3);
        ctx.stroke();
        ctx.lineWidth = 2;
        ctx.strokeStyle = track;
        ctx.beginPath();
        ctx.moveTo(Math.min(width - 2, end + 6), mid);
        ctx.lineTo(width - 2, mid);
        ctx.stroke();
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(width - 3, mid, 3, 0, Math.PI * 2);
        ctx.fill();
    }
}
