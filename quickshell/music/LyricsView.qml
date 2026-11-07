pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// Lyrics under the controls: the line being sung is bright and kept in the
// middle (synced lyrics); plain lyrics simply scroll.
Rectangle {
    id: view

    property var lyrics: ({ kind: "off", lines: [] })
    property int sung: -1

    radius: 14
    color: Theme.bgAlt

    Label {
        anchors.centerIn: parent
        visible: list.count === 0
        text: ({ loading: "Looking for the lyrics…", instrumental: "Instrumental",
                 none: "No lyrics found for this song" })[view.lyrics.kind] || ""
        small: true
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 10
        clip: true
        spacing: 6
        model: view.lyrics.lines
        currentIndex: view.lyrics.kind === "synced" ? Math.max(0, view.sung) : -1
        highlightRangeMode: view.lyrics.kind === "synced" ? ListView.ApplyRange : ListView.NoHighlightRange
        preferredHighlightBegin: height / 2 - 14
        preferredHighlightEnd: height / 2 + 14
        highlightMoveDuration: Theme.duration * 3

        delegate: Label {
            required property var modelData
            required property int index
            readonly property bool now: view.lyrics.kind === "synced" && index === view.sung
            width: ListView.view.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: modelData.text || "♪"
            color: now ? Theme.fgBright : view.lyrics.kind === "synced" ? Theme.subtle : Theme.fg
            font.weight: now ? Font.DemiBold : Font.Normal
            font.pixelSize: Math.round(Theme.fontPixels * (now ? 1.1 : 1))
        }
    }
}
