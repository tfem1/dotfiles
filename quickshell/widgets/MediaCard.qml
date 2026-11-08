import QtQuick
import "../theme"
import "../components"

// The media widget, kept minimal: the song, its artist, and the line of the
// lyrics being sung (the next one under it, dimmer).
WidgetCard {
    id: card

    property string song: ""
    property string artist: ""
    property string line: ""         // "" without synced lyrics
    property string next: ""

    title: "Now playing"

    Column {
        width: parent.width
        spacing: 3

        Label {
            width: parent.width
            text: card.song || "Nothing playing"
            color: Theme.fgBright
            font.pixelSize: Math.round(Theme.fontPixels * 1.15)
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: card.artist
            small: true
        }
        Item { width: 1; height: card.line ? 8 : 0 }
        Label {
            width: parent.width
            visible: card.line !== ""
            text: card.line
            color: Theme.accent
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            visible: card.next !== ""
            text: card.next
            small: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }
}
