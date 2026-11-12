import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import "../overlay"
import "../services"
import "../theme"
import "../wallpaper/library.js" as Library
import "settings.js" as Settings

// The Settings window (SUPER + H), on Home first. Settings are read and written by
// SettingsStore (`tfem settings`; the shell recolors itself from the new
// theme.json), and show at once when changed. System settings drive
// PipeWire, NetworkManager, BlueZ, brightnessctl and Hyprland directly;
// screens go through `tfem display` (DisplayControl).
Scope {
    id: root

    required property var wallpapers   // the wallpaper selector
    required property var network      // the network panel
    required property var modes        // Modes: game, coffee, night...
    property bool open: false
    property var pending: ({})          // Appearance changes waiting for Apply
    // Wi-Fi and Bluetooth answer through NetworkManager and BlueZ: their
    // switch shows the asked state for a moment meanwhile.
    property var radios: ({})
    property real brightness: -1
    property real uptime: 0             // seconds, read when the window opens
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"
    readonly property var adapter: Bluetooth.defaultAdapter

    function toggle() {
        open = !open;
        if (open) {
            store.refresh();
            brightnessReader.running = true;
            displayControl.refresh();
            uptimeReader.reload();
        } else {
            pending = {};
        }
    }

    function radio(name, value) {
        radios = Object.assign({}, radios, { [name]: value });
        radioWait.restart();
    }

    // The shell follows some changes at once, before theme.json is written
    // again (it brings the same values): widgets, the bar and game mode.
    function follow(key, value) {
        if (key.startsWith("widgets."))
            Theme.widgets = Object.assign({}, Theme.widgets, { [key.slice(8)]: value });
        else if (key.startsWith("bar."))
            Theme.bar = Object.assign({}, Theme.bar, { [key.slice(4)]: value });
        else if (key.startsWith("dock."))
            Theme.dock = Object.assign({}, Theme.dock, { [key.slice(5)]: value });
        else if (key === "effects.game_mode")
            Theme.gameMode = value;
    }

    function act(name, value) {
        if (name === "gamemode") {
            follow("effects.game_mode", value);
            store.change({ "effects.game_mode": value });
        } else if (name === "dock.opacity") {
            // Many values while the slider moves: the dock follows each one,
            // the file gets the last.
            follow(name, value);
            opacityWrite.value = value;
            opacityWrite.restart();
        } else if (name.startsWith("widgets.") || name.startsWith("bar.") || name.startsWith("dock.")) {
            follow(name, value);
            store.change({ [name]: value });
        } else if (name.startsWith("idle."))
            store.change({ [name]: value });
        else if (name === "volume" && Audio.sink)
            Audio.sink.audio.volume = value;
        else if (name === "muted" && Audio.sink)
            Audio.sink.audio.muted = value;
        else if (name === "microphone" && Audio.source)
            Audio.source.audio.muted = !value;
        else if (name === "brightness") {
            brightness = Math.max(0.01, value);
            Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brightness * 100) + "%"]);
        } else if (name === "wifi") {
            radio("wifi", value);
            Networking.wifiEnabled = value;
        } else if (name === "bluetooth" && adapter) {
            radio("bluetooth", value);
            adapter.enabled = value;
        }
        else if (name === "open-wifi" || name === "open-bluetooth") {
            open = false;
            network.show(name.slice(5));
        } else if (name === "next-layout")
            Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
        else if (name === "quiet")
            Session.doNotDisturb = value;
        else if (name === "awake")
            Session.stayAwake = value;
        else if (name === "mode") {
            // Not in the screenshot, and the lock screen shows alone.
            if (value === "sleep" || value.startsWith("shot-"))
                open = false;
            modes.flip(value);
        } else if (name === "display")
            displayControl.apply(value.name, value.mode, true);
        else if (name === "display-keep")
            displayControl.keep();
        else if (name === "display-revert")
            displayControl.revert();
    }

    SettingsStore {
        id: store
        cli: root.cli
        // Written: those Appearance changes no longer wait.
        onWritten: keys => root.pending = Settings.drop(root.pending, keys)
        onFailed: keys => keys.forEach(key => root.follow(key, store.settings.values[key]))
    }

    DisplayControl {
        id: displayControl
        cli: root.cli
    }

    Timer {
        id: opacityWrite
        property real value: 0.85
        interval: 400
        onTriggered: store.change({ "dock.opacity": value })
    }

    // Long enough for NetworkManager or BlueZ to answer; then the switch
    // shows their state, whatever it is.
    Timer {
        id: radioWait
        interval: 4000
        onTriggered: root.radios = {}
    }

    // "12345.67 ..." : seconds since the system started.
    FileView {
        id: uptimeReader
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.uptime = parseFloat(text()) || 0
    }

    // `brightnessctl -m` prints "device,class,current,percent%,max".
    Process {
        id: brightnessReader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                root.brightness = fields.length >= 4 ? parseInt(fields[3]) / 100 : -1;
            }
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "settings"
            dim: 0.35
            onDismissed: root.open = false

            SettingsContent {
                anchors.fill: parent
                settings: Object.assign({}, store.settings, { values: store.values })
                pending: root.pending
                busy: store.busy
                display: displayControl.listing
                confirm: displayControl.confirm
                wallpaper: Library.fileUrl(Theme.wallpaper)
                modes: root.modes.on
                about: ({
                    user: Quickshell.env("USER") || "",
                    theme: store.values["palette.source"] === "wallpaper" ? "Wallpaper colors"
                        : (Settings.theme(store.settings.themes, store.values["palette.source"]) || {}).name || "",
                    uptime: root.uptime > 0 ? Settings.uptime(root.uptime) : "",
                    system: Distro.name
                })
                live: ({
                    gameMode: !!store.values["effects.game_mode"],
                    volume: Audio.volume,
                    muted: Audio.muted,
                    micMuted: Audio.micMuted,
                    brightness: root.brightness,
                    wifi: "wifi" in root.radios ? root.radios.wifi : Networking.wifiEnabled,
                    bluetooth: "bluetooth" in root.radios ? root.radios.bluetooth
                        : root.adapter ? root.adapter.enabled : false,
                    layout: Keyboard.layout,
                    quiet: Session.doNotDisturb,
                    awake: Session.stayAwake,
                    idle: store.values
                })
                onChanged: (key, value) => root.pending = Settings.change(store.settings.values, root.pending, key, value)
                onApply: store.change(root.pending)
                onCancel: root.pending = {}
                onAction: (name, value) => root.act(name, value)
                onChooseWallpaper: {
                    root.open = false;
                    root.wallpapers.toggle();
                }
                onClosed: root.open = false
            }
        }
    }
}
