import QtQuick
import "../theme"
import "../components"

// Time in the clock color, then the date, like "17:49 • Sunday, 12/11".
// `vertical`: the hours over the minutes, no date.
Pill {
    id: chip

    property date now: new Date()

    spacing: vertical ? 0 : 8

    Label {
        text: Qt.formatDateTime(chip.now, chip.vertical ? "HH" : "HH:mm")
        color: Theme.modules.clock
        font.weight: Font.DemiBold
    }
    Label {
        text: chip.vertical ? Qt.formatDateTime(chip.now, "mm") : "•"
        color: chip.vertical ? Theme.modules.clock : Theme.muted
        font.weight: chip.vertical ? Font.DemiBold : Font.Normal
    }
    Label {
        visible: !chip.vertical
        text: Qt.formatDateTime(chip.now, "dddd, dd/MM")
        small: true
    }
}
