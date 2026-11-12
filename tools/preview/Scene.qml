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
import "../../quickshell/music"
import "../../quickshell/power"
import "../../quickshell/system"
import "../../quickshell/settings"
import "../../quickshell/dock"
import "../../quickshell/widgets"
import "../../quickshell/lock"

// A 1920x1080 desktop with the shell's components and sample data.
Rectangle {
    id: scene

    required property string themeJson
    property string bindsJson: "[]"
    property string wallpapersJson: "[]"
    property string settingsJson: "{}"
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

    // The bar as it is by default, at the top. In "bar-positions": on the
    // left, and a transparent one at the bottom.
    BarContent {
        id: sampleBar
        readonly property bool side: scene.mode === "bar-positions"
        edge: side ? "left" : "top"
        width: side ? 52 : parent.width
        height: side ? parent.height : 44
        workspaces: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(id => ({
            id: id, focused: id === 2, occupied: [1, 2, 4, 7].includes(id), urgent: false
        }))
        hasMedia: true
        mediaTitle: "Night Forest"
        mediaArtist: "Pixel Dreams"
        mediaProgress: 0.42
        mediaPlaying: true
        distro: "arch"
        now: new Date(2026, 10, 7, 17, 49)
        status: ({ keyboard: "US", volume: 0.64, network: "wifi", wifiStrength: 0.9, bluetoothOn: true,
                   bluetoothConnected: true, hasBattery: true, battery: 0.78, game: side })
    }
    BarContent {
        visible: sampleBar.side
        edge: "bottom"
        transparent: true
        x: sampleBar.width
        y: parent.height - height
        width: parent.width - sampleBar.width
        height: 44
        workspaces: sampleBar.workspaces
        now: sampleBar.now
        distro: "arch"
        status: sampleBar.status
    }

    // The dock at the bottom: pinned apps, two running, one focused.
    DockContent {
        visible: ["desktop", "widgets"].includes(scene.mode)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        fill: 0.85
        apps: [
            { id: "firefox", name: "Firefox", running: 1, focused: true },
            { id: "kitty", name: "Kitty", running: 2, focused: false },
            { id: "files", name: "Files", running: 0 },
            { id: "music", name: "Music", running: 1 },
            { id: "settings", name: "Settings", running: 0 }
        ]
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
            summary: "Night Forest"
            body: "Pixel Dreams — Night Forest"
        }
        NotificationCard {
            appName: "Battery"
            time: "2 min"
            summary: "Battery low"
            body: "15% left. Plug in the charger to keep working."
            urgent: true
        }
    }

    // The desktop widgets, with sample readings and a song with lyrics: in
    // the top left corner, and only the clock and the rings bottom right.
    component SampleWidgets: WidgetsContent {
        visible: scene.mode === "widgets"
        now: new Date(2026, 10, 7, 17, 49)
        cpu: ({ usage: 0.44, cores: 8 })
        gpu: ({ usage: 0.31, used: 2.1e9, total: 8.6e9, name: "AMD" })
        ram: ({ used: 6.2e9, total: 16.4e9 })
        disk: ({ used: 212e9, total: 494e9 })
        levels: [0.18, 0.42, 0.66, 0.92, 0.78, 0.6, 0.47, 0.58, 0.36, 0.28, 0.33, 0.45, 0.31, 0.24, 0.19, 0.14,
                 0.17, 0.11, 0.09, 0.13, 0.07, 0.05, 0.04, 0.03]
        device: "Speakers (Realtek Audio)"
        hasMedia: true
        media: ({ song: "Night Forest", artist: "Pixel Dreams",
                  line: "Under the pines the lanterns glow", next: "Walking home through falling snow" })
    }
    SampleWidgets {
        x: 24
        y: 60
    }
    SampleWidgets {
        x: parent.width - width - 24
        y: parent.height - height - 24
        show: ({ corner: "bottom-right", clock: true, cpu: true, gpu: false, ram: true, disk: false })
    }

    // The lock screen, a password being typed (the card shows).
    LockContent {
        visible: scene.mode === "lock"
        anchors.fill: parent
        z: 10
        live: false
        now: new Date(2026, 10, 7, 17, 49)
        background: scene.wallpaper
        user: "alex"
        password: "friendship"
        layout: "US"
    }

    // Launcher, clipboard, cheatsheet, selector, network: the screen dims behind them.
    Rectangle {
        visible: !["desktop", "widgets", "lock", "bar-positions"].includes(scene.mode)
        anchors.fill: parent
        anchors.topMargin: 44
        color: Qt.alpha(Theme.bgAlt, ["wifi", "bluetooth", "volume", "calendar", "music", "system"].includes(scene.mode) ? 0.2 : 0.45)

        SystemContent {
            visible: scene.mode === "system"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            width: implicitWidth
            wifi: ({ on: true, name: "Home" })
            bluetooth: ({ on: true, connected: 2 })
            doNotDisturb: true
            volume: ({ value: 0.64, muted: false })
            brightness: 0.8
            notifications: [
                { appName: "Spotify", summary: "Night Forest", body: "Pixel Dreams", time: new Date(2026, 10, 7, 17, 49) },
                { appName: "Battery", summary: "Battery low", body: "15% left. Plug in the charger.", urgent: true,
                  time: new Date(2026, 10, 7, 17, 31) },
                { appName: "Discord", summary: "Rarity", body: "Darling, the dresses are ready!", time: new Date(2026, 10, 7, 16, 58) }
            ]
        }

        PowerContent {
            visible: scene.mode === "power"
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            uptime: "3 h 12 min"
            current: 3
            armed: "reboot"
        }

        MusicContent {
            visible: scene.mode === "music"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: implicitWidth
            height: implicitHeight
            track: ({ title: "Night Forest", artist: "Pixel Dreams", album: "Night Forest",
                      playing: true, position: 47, length: 158, canSeek: true, shuffle: false, loop: "playlist" })
            players: [{ name: "Spotify", current: true }, { name: "Firefox", current: false }]
            lyrics: ({ kind: "synced", lines: [
                { time: 30, text: "Under the pines the lanterns glow" },
                { time: 36, text: "Walking home through falling snow" },
                { time: 42, text: "A little cat beside the door" },
                { time: 46, text: "Waits for me like the night before" },
                { time: 52, text: "Under the pines the lanterns glow" },
                { time: 58, text: "Walking home through falling snow" }
            ] })
        }

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
                { name: "Spotify", detail: "Night Forest · Pixel Dreams", volume: 0.8, muted: false },
                { name: "Firefox", detail: "Night Forest", volume: 0.5, muted: true },
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
                    { name: "Home", strength: 0.92, secured: true, known: true, connected: true },
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

        // Settings: Luna picked but not applied yet, so the preview, the
        // theme grid and the Apply bar show it.
        SettingsContent {
            readonly property var sample: JSON.parse(scene.settingsJson)
            visible: scene.mode.startsWith("settings")
            anchors.fill: parent
            settings: sample.values ? sample : ({ values: {}, themes: [], folders: {} })
            pending: scene.mode === "settings" ? { "palette.source": "cat-tabby", "shape.radius": 18 } : {}
            page: scene.mode === "settings" ? "appearance" : scene.mode.slice(9)
            wallpaper: scene.wallpaper
            modes: ({ game: true, night: true })
            about: ({ user: "alex", theme: "Catppuccin Mocha", uptime: "3 h 25 min", system: "Arch Linux" })
            live: ({ gameMode: false, volume: 0.64, muted: false, micMuted: false, brightness: 0.8, wifi: true,
                     bluetooth: true, layout: "French", quiet: false, awake: false, idle: sample.values || {} })
            // A 165 Hz screen just switched to 144 Hz, waiting to be kept.
            display: ({
                chosen: { "DP-1": "2560x1440@143.97" },
                monitors: [{
                    name: "DP-1", description: "Dell S2721DGF", current: "2560x1440@143.97", size: "2560x1440",
                    resolutions: [
                        { size: "2560x1440", rates: [{ label: "165 Hz", mode: "2560x1440@165.08" },
                            { label: "144 Hz", mode: "2560x1440@143.97" }, { label: "120 Hz", mode: "2560x1440@119.99" },
                            { label: "60 Hz", mode: "2560x1440@59.95" }] },
                        { size: "1920x1080", rates: [{ label: "144 Hz", mode: "1920x1080@144.00" },
                            { label: "60 Hz", mode: "1920x1080@60.00" }] },
                        { size: "1280x720", rates: [{ label: "60 Hz", mode: "1280x720@60.00" }] }]
                }, {
                    name: "HDMI-A-1", description: "LG Electronics 24MP59G", current: "1920x1080@75.00",
                    size: "1920x1080",
                    resolutions: [{ size: "1920x1080", rates: [{ label: "75 Hz", mode: "1920x1080@75.00" },
                        { label: "60 Hz", mode: "1920x1080@60.00" }] }]
                }, {
                    name: "eDP-1", description: "Laptop screen", on: false, current: "", size: "0x0",
                    resolutions: [{ size: "1920x1200", rates: [{ label: "60 Hz", mode: "1920x1200@60.00" }] }]
                }]
            })
            confirm: scene.mode === "settings-display" ? { name: "DP-1", previous: "auto", seconds: 12 } : null
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
