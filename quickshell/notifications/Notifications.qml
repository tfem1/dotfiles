import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../services"
import "../theme"

// Notification daemon: shows new notifications as popups in the top-right
// corner, for their own timeout or 5 s (urgent ones stay until closed), and
// keeps the last 50 for the system panel. Do not disturb hides the popups,
// except urgent ones; the history still gets everything.
Scope {
    id: root

    property var popups: []
    property var history: []   // [{ ref, appName, summary, body, iconSource, time, urgent }], newest first

    function remove(notification) {
        popups = popups.filter(n => n !== notification);
    }

    function forget(entry) {
        history = history.filter(other => other !== entry);
        remove(entry.ref);
        if (entry.ref)
            entry.ref.dismiss();
    }

    function clear() {
        for (const entry of history)
            if (entry.ref)
                entry.ref.dismiss();
        history = [];
        popups = [];
    }

    function iconOf(notification) {
        return notification.image || (notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "");
    }

    NotificationServer {
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: notification => {
            notification.tracked = true;
            const urgent = notification.urgency === NotificationUrgency.Critical;
            root.history = [{
                ref: notification,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                iconSource: root.iconOf(notification),
                time: new Date(),
                urgent: urgent
            }].concat(root.history).slice(0, 50);
            // Do not disturb, game, night and focus keep the popups away, not the
            // urgent ones; presentation keeps them all away (all go to history).
            const quiet = Session.doNotDisturb || Theme.gameMode || Session.night || Session.focus;
            if ((!quiet || urgent) && !Session.presentation)
                root.popups = [notification].concat(root.popups).slice(0, 4);
        }
    }

    LazyLoader {
        active: root.popups.length > 0

        PanelWindow {
            anchors {
                top: true
                right: true
            }
            margins {
                top: 8
                right: 12
            }
            exclusiveZone: 0
            implicitWidth: 380
            implicitHeight: column.implicitHeight
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-notifications"

            Column {
                id: column
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.popups

                    NotificationCard {
                        id: card
                        required property var modelData

                        width: column.width
                        appName: modelData.appName
                        summary: modelData.summary
                        body: modelData.body
                        iconSource: root.iconOf(modelData)
                        urgent: modelData.urgency === NotificationUrgency.Critical
                        time: Qt.formatTime(new Date(), "HH:mm")
                        onClosed: {
                            modelData.dismiss();
                            root.remove(modelData);
                        }

                        Timer {
                            running: !card.urgent
                            interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : 5000
                            onTriggered: root.remove(card.modelData)
                        }
                        Connections {
                            target: card.modelData
                            function onClosed() { root.remove(card.modelData); }
                        }
                    }
                }
            }
        }
    }
}
