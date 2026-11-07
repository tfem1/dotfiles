import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

// Notification daemon: keeps every notification (for the future notification
// center) and shows new ones as popups in the top-right corner, for their own
// timeout or 5 s. Urgent ones stay until closed.
Scope {
    id: root

    property var popups: []

    function remove(notification) {
        popups = popups.filter(n => n !== notification);
    }

    NotificationServer {
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: notification => {
            notification.tracked = true;
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
                        iconSource: modelData.image || (modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : "")
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
