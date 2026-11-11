import QtQuick
import "../theme"
import "resources.js" as Resources

// The desktop widgets, stacked: clock, resources (two by two, each in an
// organic shape: cookie, flower, circle, clover), audio
// spectrum, now playing. Fed by plain properties so it can be shown with
// real data (Widgets.qml) or sample data (tools/preview).
Column {
    id: column

    property var show: Theme.widgets          // which widgets (config.json widgets.*)
    property date now: new Date()
    property var cpu: ({ usage: 0, cores: 0 })
    property var gpu: ({ usage: 0, used: 0, total: 0, name: "" })   // name "": no reading
    property var ram: ({ used: 0, total: 0 })
    property var disk: ({ used: 0, total: 0 })
    property var levels: []
    property string device: ""
    property bool hasMedia: false
    property var media: ({ song: "", artist: "", line: "", next: "" })

    readonly property real half: (width - spacing) / 2
    readonly property bool rightSide: (show.corner || "").endsWith("right")   // the clock goes to that edge
    readonly property var resources: [
        { key: "cpu", name: "CPU", value: cpu.usage, detail: cpu.cores + (cpu.cores === 1 ? " core" : " cores"),
          tint: Theme.accent, shown: !!show.cpu, kind: "cookie" },
        { key: "gpu", name: "GPU", value: gpu.usage, tint: Theme.accent2, shown: !!show.gpu && gpu.name !== "", kind: "flower",
          detail: gpu.total > 0 ? Resources.usage(gpu.used, gpu.total) : gpu.name },
        { key: "ram", name: "RAM", value: ram.total > 0 ? ram.used / ram.total : 0, tint: Theme.accent3,
          detail: Resources.usage(ram.used, ram.total), shown: !!show.ram, kind: "circle" },
        { key: "disk", name: "Disk", value: disk.total > 0 ? disk.used / disk.total : 0, tint: Theme.accent,
          detail: Resources.usage(disk.used, disk.total), shown: !!show.disk, kind: "clover" }
    ].filter(entry => entry.shown)

    width: 360
    spacing: 12

    ClockPill {
        visible: !!column.show.clock
        anchors.left: column.rightSide ? undefined : parent.left
        anchors.right: column.rightSide ? parent.right : undefined
        now: column.now
    }

    Flow {
        visible: column.resources.length > 0
        width: parent.width
        spacing: column.spacing
        // In a right corner the cards fill from the right edge.
        layoutDirection: column.rightSide ? Qt.RightToLeft : Qt.LeftToRight

        Repeater {
            model: column.resources

            ResourceCard {
                required property var modelData
                width: column.half
                kind: modelData.kind
                name: modelData.name
                value: modelData.value
                detail: modelData.detail
                tint: modelData.tint
            }
        }
    }

    SpectrumCard {
        visible: !!column.show.audio
        width: parent.width
        levels: column.levels
        device: column.device
    }

    MediaCard {
        visible: !!column.show.media && column.hasMedia
        width: parent.width
        song: column.media.song
        artist: column.media.artist
        line: column.media.line
        next: column.media.next
    }
}
