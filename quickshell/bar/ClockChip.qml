import QtQuick
import "../theme"
import "../components"

// Time in the clock color, then the date, like "17:49 • Sunday, 12/11".
Pill {
    property date now: new Date()

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(now, "HH:mm")
        color: Theme.modules.clock
        font.weight: Font.DemiBold
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: "•"
        color: Theme.muted
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(now, "dddd, dd/MM")
        small: true
    }
}
