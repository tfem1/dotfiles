import QtQuick
import Quickshell
import "colors.js" as Colors
import "library.js" as Library

// Finds the color class of images, one after the other, with Quickshell's
// ColorQuantizer: it reads each image in a worker thread, scaled to 64 px,
// and gives its 8 main colors (each one an equal share of the pixels).
// The selector keeps the answers, so each wallpaper is read once.
// Give it `queue` (file paths, the first is read); it answers with
// sampled(path, color, palette) (palette: the 8 colors, "#rrggbb,..."), and
// the owner takes that path out of the queue.
ColorQuantizer {
    id: probe

    property var queue: []
    readonly property string path: queue.length > 0 ? queue[0] : ""
    signal sampled(string path, string color, string palette)

    source: Library.fileUrl(path)
    depth: 3
    rescaleSize: 64

    onSourceChanged: path ? giveUp.restart() : giveUp.stop()
    onColorsChanged: {
        if (!path)
            return;
        giveUp.stop();
        sampled(path, Colors.dominantColors(colors), Colors.palette(colors));
    }

    // An image that never comes back is filed as gray.
    property Timer giveUp: Timer {
        interval: 10000
        onTriggered: if (probe.path) probe.sampled(probe.path, "gray", "")
    }
}
