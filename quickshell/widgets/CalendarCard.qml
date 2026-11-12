pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../calendar/calendar.js" as Cal

// The calendar widget: this month, its weeks starting on the first day of
// the user's language, today in the accent color.
WidgetCard {
    id: card

    property date now: new Date()
    readonly property var locale: Qt.locale()
    readonly property var cells: Cal.monthGrid(now.getFullYear(), now.getMonth(), locale.firstDayOfWeek, now)
    // Only the rows this month uses (5 most of the time).
    readonly property int rows: cells.slice(35).some(cell => cell.inMonth) ? 6 : 5

    title: Cal.title(locale.standaloneMonthName(now.getMonth(), Locale.LongFormat), now.getFullYear())

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
                horizontalAlignment: Text.AlignHCenter
                text: card.locale.dayName((card.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                small: true
                color: Theme.subtle
            }
        }
        Repeater {
            model: card.cells.slice(0, card.rows * 7)

            Item {
                id: day
                required property var modelData
                width: grid.cell
                height: 26

                Rectangle {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    visible: day.modelData.today
                    color: Theme.accent
                }
                Label {
                    anchors.centerIn: parent
                    text: day.modelData.day
                    small: !day.modelData.today
                    font.weight: day.modelData.today ? Font.Bold : Font.Normal
                    color: day.modelData.today ? Theme.bg : !day.modelData.inMonth ? Qt.alpha(Theme.subtle, 0.45)
                        : day.modelData.weekend ? Theme.accent2 : Theme.fg
                }
            }
        }
    }
}
