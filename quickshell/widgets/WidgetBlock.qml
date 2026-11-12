pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "resources.js" as Resources

// One desktop widget, by name: clock, resources (CPU, GPU, RAM, disk two by
// two, in organic shapes), audio (spectrum), media (now playing) or
// calendar. `feed` holds what they show (see WidgetsContent).
Item {
    id: block

    property string name: ""
    property var feed: ({})
    property bool rightSide: false          // in a right corner: cards fill from the right
    readonly property var show: feed.show || ({})
    readonly property var resources: {
        const f = feed, s = show;
        const cpu = f.cpu || {}, gpu = f.gpu || {}, ram = f.ram || {}, disk = f.disk || {};
        return [
            { name: "CPU", value: cpu.usage || 0, detail: (cpu.cores || 0) + (cpu.cores === 1 ? " core" : " cores"),
              tint: Theme.accent, shown: !!s.cpu, kind: "cookie" },
            { name: "GPU", value: gpu.usage || 0, tint: Theme.accent2, shown: !!s.gpu && !!gpu.name, kind: "flower",
              detail: gpu.total > 0 ? Resources.usage(gpu.used, gpu.total) : (gpu.name || "") },
            { name: "RAM", value: ram.total > 0 ? ram.used / ram.total : 0, tint: Theme.accent3,
              detail: Resources.usage(ram.used || 0, ram.total || 0), shown: !!s.ram, kind: "circle" },
            { name: "Disk", value: disk.total > 0 ? disk.used / disk.total : 0, tint: Theme.accent,
              detail: Resources.usage(disk.used || 0, disk.total || 0), shown: !!s.disk, kind: "clover" }
        ].filter(entry => entry.shown);
    }
    readonly property bool shown: ({
        clock: !!show.clock, resources: resources.length > 0, audio: !!show.audio,
        media: !!show.media && !!feed.hasMedia, calendar: !!show.calendar
    })[name] || false

    objectName: name
    implicitWidth: name === "clock" && loader.item ? loader.item.implicitWidth : 360
    implicitHeight: loader.item ? loader.item.height : 0
    width: implicitWidth
    height: implicitHeight

    Loader {
        id: loader
        active: block.shown
        sourceComponent: ({ clock: clock, resources: cards, audio: audio, media: media, calendar: calendar })[block.name] || null
    }

    Component {
        id: clock
        ClockPill { now: block.feed.now || new Date() }
    }
    Component {
        id: cards
        Flow {
            width: 360
            spacing: 12
            layoutDirection: block.rightSide ? Qt.RightToLeft : Qt.LeftToRight
            Repeater {
                model: block.resources
                ResourceCard {
                    required property var modelData
                    width: (360 - 12) / 2
                    kind: modelData.kind
                    name: modelData.name
                    value: modelData.value
                    detail: modelData.detail
                    tint: modelData.tint
                }
            }
        }
    }
    Component {
        id: audio
        SpectrumCard {
            width: 360
            levels: block.feed.levels || []
            device: block.feed.device || ""
        }
    }
    Component {
        id: media
        MediaCard {
            width: 360
            readonly property var info: block.feed.media || {}
            song: info.song || ""
            artist: info.artist || ""
            line: info.line || ""
            next: info.next || ""
        }
    }
    Component {
        id: calendar
        CalendarCard {
            width: 360
            now: block.feed.now || new Date()
        }
    }
}
