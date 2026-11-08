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

// The Settings window (SUPER + H). Reads every setting with `tfem settings
// get`; writes with `tfem settings set`, which regenerates the theme (the
// shell recolors itself from the new theme.json). System settings drive
// PipeWire, NetworkManager, BlueZ, brightnessctl and Hyprland directly;
// screens go through `tfem display` (DisplayControl).
Scope {
    id: root

    required property var wallpapers   // the wallpaper selector
    required property var network      // the network panel
    property bool open: false
    property var settings: ({ values: {}, themes: [], folders: {} })
    property var pending: ({})
    property var queue: []              // `set` calls waiting for the one running
    property var writing: []            // keys of the call running
    property real brightness: -1
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"
    readonly property var adapter: Bluetooth.defaultAdapter

    function toggle() {
        open = !open;
        if (open) {
            reader.running = true;
            brightnessReader.running = true;
            displayControl.refresh();
        } else {
            pending = {};
        }
    }

    // One `tfem settings set` at a time; the others wait their turn.
    function set(pairs) {
        if (writer.running) {
            queue = queue.concat([pairs]);
            return;
        }
        writing = pairs.map(pair => pair.split("=")[0]);
        writer.command = [cli, "settings", "set"].concat(pairs);
        writer.running = true;
    }

    function act(name, value) {
        if (name === "gamemode")
            set(["effects.game_mode=" + value]);
        else if (name.startsWith("idle.") || name.startsWith("widgets."))
            set([name + "=" + value]);
        else if (name === "volume" && Audio.sink)
            Audio.sink.audio.volume = value;
        else if (name === "muted" && Audio.sink)
            Audio.sink.audio.muted = value;
        else if (name === "microphone" && Audio.source)
            Audio.source.audio.muted = !value;
        else if (name === "brightness") {
            brightness = Math.max(0.01, value);
            Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brightness * 100) + "%"]);
        } else if (name === "wifi")
            Networking.wifiEnabled = value;
        else if (name === "bluetooth" && adapter)
            adapter.enabled = value;
        else if (name === "open-wifi" || name === "open-bluetooth") {
            open = false;
            network.show(name.slice(5));
        } else if (name === "next-layout")
            Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
        else if (name === "quiet")
            Session.doNotDisturb = value;
        else if (name === "awake")
            Session.stayAwake = value;
        else if (name === "display")
            displayControl.apply(value.name, value.mode, true);
        else if (name === "display-keep")
            displayControl.keep();
        else if (name === "display-revert")
            displayControl.revert();
    }

    DisplayControl {
        id: displayControl
        cli: root.cli
    }

    Process {
        id: reader
        command: [root.cli, "settings", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settings = JSON.parse(text);
                } catch (error) {
                    console.warn("settings: cannot read them:", error);
                }
            }
        }
    }

    Process {
        id: writer
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0)
                console.warn("settings: not applied:", errors.text.trim());
            else
                root.pending = Object.fromEntries(Object.entries(root.pending)
                    .filter(([key]) => !root.writing.includes(key)));
            root.writing = [];
            reader.running = true;
            if (root.queue.length > 0) {
                const next = root.queue[0];
                root.queue = root.queue.slice(1);
                root.set(next);
            }
        }
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
                settings: root.settings
                pending: root.pending
                busy: writer.running
                display: displayControl.listing
                confirm: displayControl.confirm
                wallpaper: Library.fileUrl(Theme.wallpaper)
                live: ({
                    gameMode: !!root.settings.values["effects.game_mode"],
                    volume: Audio.volume,
                    muted: Audio.muted,
                    micMuted: Audio.micMuted,
                    brightness: root.brightness,
                    wifi: Networking.wifiEnabled,
                    bluetooth: root.adapter ? root.adapter.enabled : false,
                    layout: Keyboard.layout,
                    quiet: Session.doNotDisturb,
                    awake: Session.stayAwake,
                    idle: root.settings.values
                })
                onChanged: (key, value) => root.pending = Settings.change(root.settings.values, root.pending, key, value)
                onApply: root.set(Settings.pairs(root.pending))
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
