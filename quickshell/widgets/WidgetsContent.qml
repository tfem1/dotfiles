pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// The desktop widgets stacked in their corner: clock, resources (two by
// two, each in an organic shape: cookie, flower, circle, clover), audio
// spectrum, now playing, calendar. Widgets moved elsewhere (`places`) leave
// the stack. Fed by plain properties so it can be shown with real data
// (Widgets.qml) or sample data (tools/preview).
Column {
    id: column

    property var show: Theme.widgets          // which widgets (config.json widgets.*)
    property var places: ({})                 // name -> [x, y]: shown elsewhere
    property date now: new Date()
    property var cpu: ({ usage: 0, cores: 0 })
    property var gpu: ({ usage: 0, used: 0, total: 0, name: "" })   // name "": no reading
    property var ram: ({ used: 0, total: 0 })
    property var disk: ({ used: 0, total: 0 })
    property var levels: []
    property string device: ""
    property bool hasMedia: false
    property var media: ({ song: "", artist: "", line: "", next: "" })

    readonly property var names: ["clock", "resources", "audio", "media", "calendar"]
    readonly property bool rightSide: (show.corner || "").endsWith("right")   // the clock goes to that edge
    // Everything the widgets show, in one object (for WidgetBlock).
    readonly property var feed: ({
        show: show, now: now, cpu: cpu, gpu: gpu, ram: ram, disk: disk, levels: levels,
        device: device, hasMedia: hasMedia, media: media
    })

    width: 360
    spacing: 12

    Repeater {
        model: column.names

        WidgetBlock {
            required property string modelData
            name: modelData
            feed: column.feed
            rightSide: column.rightSide
            visible: shown && !(modelData in column.places)
            anchors.left: column.rightSide ? undefined : parent.left
            anchors.right: column.rightSide ? parent.right : undefined
        }
    }
}
