import QtQuick
import "../theme"
import "../components"

// The short date, then the time on a lit chip: "ven. 13/11 [7:08 AM]", in
// the system's language and 12 or 24 hour format. `vertical`: the hours
// over the minutes, no date.
Pill {
    id: chip

    property date now: new Date()

    padding: 6
    spacing: vertical ? 0 : 8

    Label {
        visible: !chip.vertical
        leftPadding: 6
        text: chip.now.toLocaleString(Qt.locale(), "ddd")
        font.weight: Font.DemiBold
        color: Theme.fgBright
    }
    Label {
        visible: !chip.vertical
        text: chip.now.toLocaleString(Qt.locale(), "dd/MM")
        font.weight: Font.DemiBold
        color: Theme.modules.clock
    }
    Rectangle {
        width: (chip.vertical ? stacked.implicitWidth : time.implicitWidth) + 16
        height: chip.vertical ? stacked.implicitHeight + 10 : 22
        radius: 11
        color: Qt.alpha(Theme.modules.clock, 0.28)

        Label {
            id: time
            visible: !chip.vertical
            anchors.centerIn: parent
            text: chip.now.toLocaleString(Qt.locale(), Qt.locale().timeFormat(Locale.ShortFormat).replace(":ss", ""))
            font.weight: Font.Bold
            color: Theme.fgBright
        }
        Column {
            id: stacked
            visible: chip.vertical
            anchors.centerIn: parent
            Label { text: Qt.formatDateTime(chip.now, "HH"); font.weight: Font.Bold; color: Theme.fgBright }
            Label { text: Qt.formatDateTime(chip.now, "mm"); font.weight: Font.Bold; color: Theme.fgBright }
        }
    }
}
