import QtQuick
import "../../quickshell/theme"
import "../../quickshell/bar"
import "../../quickshell/osd"
import "../../quickshell/notifications"
import "../../quickshell/launcher"
import "../../quickshell/clipboard"
import "../../quickshell/cheatsheet"
import "../../quickshell/wallpaper"
import "../../quickshell/network"
import "../../quickshell/volume"
import "../../quickshell/calendar"

// A 1920x1080 desktop with the shell's components and sample data.
Rectangle {
    id: scene

    required property string themeJson
    property string bindsJson: "[]"
    property string wallpapersJson: "[]"
    property string localeName: ""
    property url wallpaper
    property string mode: "desktop"

    width: 1920
    height: 1080
    color: Theme.bgAlt
    Component.onCompleted: Theme.apply(JSON.parse(themeJson))

    Image {
        anchors.fill: parent
        source: scene.wallpaper
        fillMode: Image.PreserveAspectCrop
    }

    BarContent {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        workspaces: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(id => ({
            id: id, focused: id === 2, occupied: [1, 2, 4, 7].includes(id), urgent: false
        }))
        hasMedia: true
        mediaTitle: "Winter Wrap Up"
        mediaArtist: "Ponyville Chorus"
        mediaProgress: 0.42
        mediaPlaying: true
        now: new Date(2026, 10, 7, 17, 49)
        status.keyboard: "US"
        status.volume: 0.64
        status.network: "wifi"
        status.wifiStrength: 0.9
        status.bluetoothOn: true
        status.bluetoothConnected: true
        status.hasBattery: true
        status.battery: 0.78
    }

    // Desktop: volume OSD and two notifications (one urgent).
    OsdContent {
        visible: scene.mode === "desktop"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 70
        icon: "volume_up"
        value: 0.64
    }

    Column {
        visible: scene.mode === "desktop"
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 58
        spacing: 10

        NotificationCard {
            appName: "Spotify"
            time: "now"
            summary: "Winter Wrap Up"
            body: "Ponyville Chorus — Season 1 Soundtrack"
        }
        NotificationCard {
            appName: "Battery"
            time: "2 min"
            summary: "Battery low"
            body: "15% left. Plug in the charger to keep working."
            urgent: true
        }
    }

    // Launcher, clipboard, cheatsheet, selector, network: the screen dims behind them.
    Rectangle {
        visible: scene.mode !== "desktop"
        anchors.fill: parent
        anchors.topMargin: 44
        color: Qt.alpha(Theme.bgAlt, ["wifi", "bluetooth", "volume", "calendar"].includes(scene.mode) ? 0.2 : 0.45)

        VolumeContent {
            visible: scene.mode === "volume"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: implicitWidth
            height: implicitHeight
            output: ({ name: "Speakers", volume: 0.64, muted: false, devices: [
                { name: "Speakers", current: true },
                { name: "Pinkie's Headphones", current: false },
                { name: "HDMI / DisplayPort", current: false }
            ] })
            input: ({ name: "Built-in microphone", volume: 0.8, muted: false, devices: [
                { name: "Built-in microphone", current: true },
                { name: "Webcam microphone", current: false }
            ] })
            apps: [
                { name: "Spotify", detail: "Winter Wrap Up · Ponyville Chorus", volume: 0.8, muted: false },
                { name: "Firefox", detail: "Friendship is Magic, season 1", volume: 0.5, muted: true },
                { name: "Discord", detail: "", volume: 0.7, muted: false }
            ]
        }

        CalendarContent {
            visible: scene.mode === "calendar"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: implicitWidth
            height: implicitHeight
            now: new Date(2026, 10, 7, 17, 49)
            locale: scene.localeName ? Qt.locale(scene.localeName) : Qt.locale()
        }

        NetworkContent {
            visible: scene.mode === "wifi" || scene.mode === "bluetooth"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: implicitWidth
            height: implicitHeight
            tab: scene.mode === "bluetooth" ? "bluetooth" : "wifi"
            wifi: ({
                active: true, scanning: false, wired: "", connectivity: "full",
                networks: [
                    { name: "Ponyville Library", strength: 0.92, secured: true, known: true, connected: true },
                    { name: "Sweet Apple Acres", strength: 0.71, secured: true, known: true },
                    { name: "Sugarcube Corner", strength: 0.62, secured: true, needsPassword: true, failed: "wrong" },
                    { name: "Canterlot Guest", strength: 0.55, secured: false },
                    { name: "Cloudsdale 5G", strength: 0.38, secured: true, needsPassword: true },
                    { name: "Everfree Forest", strength: 0.18, secured: true, needsPassword: true }
                ]
            })
            bluetooth: ({
                available: true, active: true, discovering: true, discoverable: false, name: "desktop",
                devices: [
                    { name: "Pinkie's Headphones", kind: "headphones", paired: true, connected: true, battery: 0.8 },
                    { name: "MX Master 3", kind: "mouse", paired: true, connected: true, battery: 0.45 },
                    { name: "Keychron K2", kind: "keyboard_alt", paired: true, connected: false, battery: -1 },
                    { name: "DualSense", kind: "sports_esports", paired: false, battery: -1 },
                    { name: "Rarity's Phone", kind: "smartphone", paired: false, busy: true, battery: -1 }
                ]
            })
        }

        LauncherContent {
            visible: scene.mode === "launcher"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 220
            width: 560
            height: implicitHeight
            query: "f"
            apps: [
                { name: "Firefox", comment: "Web browser" },
                { name: "Files", comment: "Access and organize files" },
                { name: "Fastfetch", comment: "System information in the terminal" },
                { name: "Flatseal", comment: "Manage Flatpak permissions" },
                { name: "Font Viewer", comment: "View fonts on your system" }
            ]
        }

        ClipboardContent {
            visible: scene.mode === "clipboard"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 220
            width: 560
            height: implicitHeight
            entries: [
                { text: "Friendship is magic" },
                { text: "https://wallhaven.cc/w/wymvyx" },
                { text: "Image · 214 KiB png 1920x1080", image: true },
                { text: "sudo pacman -Syu" },
                { text: "#d19fe4" },
                { text: "Dear Princess Celestia, today I learned that…" }
            ]
        }

        SelectorContent {
            readonly property var samples: JSON.parse(scene.wallpapersJson)
            visible: scene.mode === "wallpaper"
            anchors.fill: parent
            images: samples
            current: samples.length > 3 ? samples[3].path : ""
        }

        CheatsheetContent {
            visible: scene.mode === "cheatsheet"
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            binds: JSON.parse(scene.bindsJson)
        }
    }
}
