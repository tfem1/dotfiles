pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "calendar.js" as Cal

// The calendar (SUPER + S, or a click on the clock): today's time and date,
// then a month with week numbers. Arrows or the mouse wheel change the
// month; the weeks start on the first day of your language's week.
Rectangle {
    id: sheet

    property date now: new Date()
    property var locale: Qt.locale()
    property int year: now.getFullYear()
    property int month: now.getMonth()
    signal closed

    readonly property color tint: Theme.modules.clock
    readonly property var cells: Cal.monthGrid(year, month, locale.firstDayOfWeek, now)
    readonly property var weeks: Cal.rowWeeks(cells)
    readonly property bool onToday: year === now.getFullYear() && month === now.getMonth()

    function shift(step) {
        const date = new Date(year, month + step, 1);
        year = date.getFullYear();
        month = date.getMonth();
    }

    function showToday() {
        year = now.getFullYear();
        month = now.getMonth();
    }

    implicitWidth: 360
    implicitHeight: column.implicitHeight + 36
    radius: Theme.radius + 8
    color: Theme.panel
    focus: true
    Keys.onEscapePressed: closed()
    Keys.onLeftPressed: shift(-1)
    Keys.onRightPressed: shift(1)

    // Keeps clicks inside from closing it.
    MouseArea {
        anchors.fill: parent
    }
    WheelHandler {
        onWheel: event => sheet.shift(event.angleDelta.y > 0 ? -1 : 1)
    }

    Column {
        id: column
        x: 18
        y: 18
        width: parent.width - 36
        spacing: 12

        Column {
            Label {
                text: Qt.formatTime(sheet.now, "HH:mm")
                color: Theme.fgBright
                font.pixelSize: Math.round(Theme.fontPixels * 2.6)
                font.weight: Font.DemiBold
            }
            Label {
                text: Cal.title(sheet.now.toLocaleDateString(sheet.locale, "dddd d MMMM yyyy"), "").trim()
                color: sheet.tint
            }
        }

        Item {
            width: parent.width
            height: 34

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Cal.title(sheet.locale.standaloneMonthName(sheet.month, Locale.LongFormat), sheet.year)
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Rectangle {
                    visible: !sheet.onToday
                    anchors.verticalCenter: parent.verticalCenter
                    width: todayLabel.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: Qt.alpha(sheet.tint, 0.2)
                    Label { id: todayLabel; anchors.centerIn: parent; text: "Today"; small: true; color: sheet.tint }
                    TapHandler { onTapped: sheet.showToday() }
                }
                IconButton { icon: "chevron_left"; onClicked: sheet.shift(-1) }
                IconButton { icon: "chevron_right"; onClicked: sheet.shift(1) }
            }
        }

        Grid {
            id: grid
            columns: 8
            columnSpacing: 0
            rowSpacing: 2
            readonly property real cell: (column.width - 2) / 8

            // Header: the week-number column, then the day names.
            Item { width: grid.cell; height: 24 }
            Repeater {
                model: 7
                Label {
                    required property int index
                    width: grid.cell
                    height: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: sheet.locale.dayName((sheet.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                    small: true
                    font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: 48   // 6 rows of week number + 7 days

                Item {
                    id: slot
                    required property int index
                    readonly property bool weekColumn: index % 8 === 0
                    readonly property var day: weekColumn ? null : sheet.cells[Math.floor(index / 8) * 7 + index % 8 - 1]
                    width: grid.cell
                    height: grid.cell - 4

                    Label {
                        visible: slot.weekColumn
                        anchors.centerIn: parent
                        text: sheet.weeks[Math.floor(slot.index / 8)]
                        small: true
                        color: Theme.muted
                    }
                    Rectangle {
                        visible: !slot.weekColumn
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4
                        height: width
                        radius: width / 2
                        color: slot.day && slot.day.today ? sheet.tint : hover.hovered ? Theme.surface : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: slot.day ? slot.day.day : ""
                            color: !slot.day ? Theme.fg : slot.day.today ? Theme.bg
                                : !slot.day.inMonth ? Theme.muted : slot.day.weekend ? Theme.subtle : Theme.fg
                            font.weight: slot.day && slot.day.today ? Font.Bold : Font.Normal
                        }
                        HoverHandler { id: hover }
                    }
                }
            }
        }
    }
}
