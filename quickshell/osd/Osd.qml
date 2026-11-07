import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"

// Volume and brightness OSD under the bar, shown 1.5 s after each change.
// Volume changes are watched; brightness is announced by the keybinds (IPC).
Scope {
    id: root

    property string icon: "volume_up"
    property real value: 0
    property color tone: Theme.modules.audio
    property bool off: false
    property bool shown: false
    property bool ready: false   // ignores the first values read at startup

    function show(icon, value, tone, off) {
        root.icon = icon;
        root.value = value;
        root.tone = tone;
        root.off = off;
        root.shown = true;
        hide.restart();
    }

    function showVolume() {
        if (ready)
            show(Audio.muted ? "volume_off" : "volume_up", Audio.volume, Theme.modules.audio, Audio.muted);
    }

    function showBrightness() {
        brightness.running = true;
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.showVolume(); }
        function onMutedChanged() { root.showVolume(); }
    }

    Timer { interval: 2000; running: true; onTriggered: root.ready = true }
    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    // `brightnessctl -m` prints "device,class,current,percent%,max".
    Process {
        id: brightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                root.show("brightness_6", parseInt(fields[3]) / 100, Theme.modules.brightness, false);
            }
        }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            anchors.top: true
            margins.top: 56
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: osd.implicitWidth
            implicitHeight: osd.implicitHeight
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-osd"

            OsdContent {
                id: osd
                anchors.fill: parent
                icon: root.icon
                value: root.value
                tone: root.tone
                off: root.off
            }
        }
    }
}
