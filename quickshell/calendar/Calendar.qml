import QtQuick
import Quickshell
import "../overlay"

// Opens the calendar under the clock. Only loaded while open.
Scope {
    id: root

    property bool open: false

    function toggle() {
        open = !open;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.open
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "calendar"
            dim: 0.2
            onDismissed: root.open = false

            CalendarContent {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10
                width: implicitWidth
                height: implicitHeight
                now: clock.date
                onClosed: root.open = false
                Component.onCompleted: {
                    showToday();
                    forceActiveFocus();
                }
            }
        }
    }
}
