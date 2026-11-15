pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../calendar/calendar.js" as Cal

// The calendar widget, like the music ones: today's number in a scalloped
// shape with the month and the weekday, this month's days (weeks start on
// the first day of the user's language; today in the same shape, weekends
// in the second color), and a wave as far as the month has gone.
WidgetCard {
    id: card

    property date now: new Date()
    readonly property var locale: Qt.locale()
    readonly property var cells: Cal.monthGrid(now.getFullYear(), now.getMonth(), locale.firstDayOfWeek, now)
    // Only the rows this month uses (5 most of the time).
    readonly property int rows: cells.slice(35).some(cell => cell.inMonth) ? 6 : 5
    readonly property int days: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()

    Column {
        width: parent.width
        spacing: 12

        Row {
            width: parent.width
            spacing: 12
            Item {
                width: 48
                height: 48
                OrganicShape {
                    anchors.fill: parent
                    kind: "cookie"
                    fill: Qt.alpha(Theme.accent, 0.4)
                }
                Label {
                    anchors.centerIn: parent
                    text: card.now.getDate()
                    color: Theme.fgBright
                    font.pixelSize: Math.round(Theme.fontPixels * 1.3)
                    font.weight: Font.Bold
                }
            }
            Column {
                width: parent.width - 48 - 34 - 24
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: Cal.title(card.locale.standaloneMonthName(card.now.getMonth(), Locale.LongFormat),
                                    card.now.getFullYear())
                    color: Theme.fgBright
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Label {
                    text: card.locale.standaloneDayName(card.now.getDay(), Locale.LongFormat)
                    small: true
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 28
                radius: 10
                color: Qt.alpha(Theme.accent, 0.35)
                Icon {
                    anchors.centerIn: parent
                    name: "calendar_month"
                    color: Theme.fgBright
                    size: 16
                }
            }
        }

        Grid {
            id: grid
            width: parent.width
            columns: 7
            readonly property real cell: width / 7

            Repeater {
                model: 7
                Label {
                    required property int index
                    width: grid.cell
                    bottomPadding: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: card.locale.dayName((card.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).charAt(0).toUpperCase()
                    small: true
                    font.weight: Font.DemiBold
                    color: Theme.subtle
                }
            }
            Repeater {
                model: card.cells.slice(0, card.rows * 7)

                Item {
                    id: day
                    required property var modelData
                    width: grid.cell
                    height: 32

                    OrganicShape {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        visible: day.modelData.today
                        kind: "cookie"
                        fill: Theme.accent
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: day.modelData.inMonth
                        text: day.modelData.day
                        font.weight: day.modelData.today ? Font.Bold : Font.Normal
                        color: day.modelData.today ? Theme.bg : day.modelData.weekend ? Theme.accent2 : Theme.fg
                    }
                }
            }
        }

        WavyLine {   // how far the month has gone
            width: parent.width
            progress: card.now.getDate() / card.days
        }
    }
}
