import QtQuick
import "../theme"
import "../components"
import "layout.js" as Layout

// Everything drawn in the bar, fed by plain properties so it can be shown
// with real data (Bar.qml) or sample data (tools/preview). `edge`: the side
// of the screen it stands on; on the left or right, everything is stacked.
// `transparent`: no background, only the pills show.
Rectangle {
    id: bar

    property string edge: "top"         // top | bottom | left | right
    property bool transparent: false
    property var workspaces: []
    property bool hasMedia: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property real mediaProgress: 0
    property bool mediaPlaying: false
    property date now: new Date()
    property string distro: ""      // os-release ID, for the logo at the start
    property var status: ({})       // see StatusArea
    property string layout: ""      // config.json bar.layout, see layout.js
    property string workspaceStyle: "dots"   // config.json bar.workspaces
    readonly property var zones: Layout.parse(layout)
    readonly property bool vertical: edge === "left" || edge === "right"
    // The notch hangs from the screen edge, unless the bar has no background.
    readonly property bool notch: !transparent

    signal workspaceClicked(int id)
    signal mediaToggled
    signal rightClicked
    signal clockClicked
    signal powerClicked
    signal logoClicked
    signal updatesClicked

    implicitHeight: vertical ? 600 : 44
    implicitWidth: vertical ? 52 : 1200
    color: transparent ? "transparent" : Theme.panel

    // The three zones: at the start, in the middle and at the end of the bar.
    component Zone: Grid {
        property var modules: []
        columns: bar.vertical ? 1 : -1
        rows: bar.vertical ? -1 : 1
        spacing: 8
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: parent.modules
            Loader {
                required property string modelData
                // (ids end in "Module": inside a Loader, "status" is its own property)
                sourceComponent: ({ logo: logoModule, media: mediaModule, workspaces: workspacesModule,
                                    clock: clockModule, status: statusModule, power: powerModule,
                                    notifications: notificationsModule })[modelData]
            }
        }
    }

    Zone {
        modules: bar.zones.start
        x: bar.vertical ? (bar.width - width) / 2 : 10
        y: bar.vertical ? 10 : (bar.height - height) / 2
    }
    Zone {
        modules: bar.zones.center
        anchors.centerIn: parent
    }
    Zone {
        modules: bar.zones.end
        x: bar.vertical ? (bar.width - width) / 2 : bar.width - width - 10
        y: bar.vertical ? bar.height - height - 10 : (bar.height - height) / 2
    }

    Component {
        id: logoModule
        DistroButton {
            vertical: bar.vertical
            distro: bar.distro
            onClicked: bar.logoClicked()
        }
    }
    Component {
        id: mediaModule
        MediaChip {
            vertical: bar.vertical
            title: bar.mediaTitle
            artist: bar.mediaArtist
            progress: bar.mediaProgress
            playing: bar.mediaPlaying
            onToggle: bar.mediaToggled()
        }
    }
    Component {
        id: workspacesModule
        WorkspaceNotch {
            edge: bar.edge
            vertical: bar.vertical
            hanging: bar.notch && bar.workspaceStyle !== "dots"
            style: bar.workspaceStyle
            workspaces: bar.workspaces
            barWidth: bar.width
            barHeight: bar.height
            onClicked: id => bar.workspaceClicked(id)
        }
    }
    Component {
        id: clockModule
        ClockChip {
            vertical: bar.vertical
            now: bar.now
            onClicked: bar.clockClicked()
        }
    }
    Component {
        id: statusModule
        StatusArea {
            vertical: bar.vertical
            status: bar.status
            onClicked: bar.rightClicked()
            onUpdatesClicked: bar.updatesClicked()
        }
    }
    // The notifications: a click opens the system panel and its history.
    Component {
        id: notificationsModule
        Pill {
            vertical: bar.vertical
            padding: 8
            onClicked: bar.rightClicked()

            Icon {
                name: (bar.status || {}).quiet ? "notifications_off" : "notifications"
                color: Theme.fg
                size: 17
            }
        }
    }
    // Opens the power menu.
    Component {
        id: powerModule
        Pill {
            vertical: bar.vertical
            padding: 9
            onClicked: bar.powerClicked()

            Icon {
                name: "power_settings_new"
                color: Theme.accent2
                size: 17
            }
        }
    }
}
