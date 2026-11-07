pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "kinds.js" as Kinds

// The Wi-Fi tab: cable connection, internet warning, then every network,
// connected and saved ones first. A secured network asks for its password
// in place. `networks` items: { ref, name, strength, secured, needsPassword,
// known, connected, busy, failed }.
Item {
    id: page

    property bool active: true         // Wi-Fi turned on
    property bool scanning: false
    property string wired: ""          // name of the cable connection, "" for none
    property string connectivity: "full"
    property var networks: []
    property string expandedName: ""   // network showing its password field
    signal enableRequested
    signal scanRequested
    signal connectRequested(var ref, string password)
    signal disconnectRequested(var ref)
    signal forgetRequested(var ref)

    readonly property color tint: Theme.modules.wifi
    readonly property var sorted: Kinds.sortNetworks(networks)

    function activate(network) {
        if (network.connected)
            return;
        if (network.needsPassword) {
            expandedName = expandedName === network.name ? "" : network.name;
            return;
        }
        expandedName = "";
        connectRequested(network.ref, "");
    }

    // A network that turns out to need a password opens its field.
    onNetworksChanged: {
        const asking = networks.find(network => network.failed === "password" || network.failed === "wrong");
        if (asking)
            expandedName = asking.name;
    }

    Column {
        anchors.centerIn: parent
        visible: !page.active
        spacing: 12

        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "wifi_off"; color: Theme.subtle; size: 40 }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Wi-Fi is off"; color: Theme.fg }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 120
            height: 36
            radius: 18
            color: page.tint
            Label { anchors.centerIn: parent; text: "Turn on"; color: Theme.bg; font.weight: Font.DemiBold }
            TapHandler { onTapped: page.enableRequested() }
        }
    }

    Flickable {
        anchors.fill: parent
        visible: page.active
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 4

            Row {
                visible: page.wired !== ""
                spacing: 12
                leftPadding: 12
                height: 40
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "cable"; color: Theme.modules.network; size: 20 }
                Label { anchors.verticalCenter: parent.verticalCenter; text: "Cable · " + page.wired; color: Theme.fg }
            }
            Label {
                visible: page.connectivity === "limited" || page.connectivity === "portal"
                width: parent.width
                leftPadding: 12
                text: page.connectivity === "portal" ? "This network wants you to sign in (open a browser)"
                                                     : "Connected, but no internet"
                color: Theme.yellow
                small: true
                wrapMode: Text.WordWrap
            }

            Item {
                width: parent.width
                height: 36
                Label { anchors.verticalCenter: parent.verticalCenter; x: 12; text: "Networks"; small: true; font.weight: Font.DemiBold }
                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "refresh"
                    tint: page.tint
                    spinning: page.scanning
                    onClicked: page.scanRequested()
                }
            }

            Repeater {
                model: page.sorted

                WifiItem {
                    required property var modelData
                    width: content.width
                    network: modelData
                    expanded: page.expandedName === modelData.name && !modelData.connected
                    onExpandedChanged: if (expanded) focusPassword()
                    onActivated: page.activate(modelData)
                    onPasswordEntered: password => {
                        page.expandedName = "";
                        page.connectRequested(modelData.ref, password);
                    }
                    onDisconnectRequested: page.disconnectRequested(modelData.ref)
                    onForgetRequested: page.forgetRequested(modelData.ref)
                }
            }

            Label {
                visible: page.sorted.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 24
                text: page.scanning ? "Looking for networks…" : "No network found"
                small: true
            }
        }
    }
}
