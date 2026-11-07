import QtQuick
import Quickshell
import Quickshell.Io

// Commands sent by the Hyprland keybinds:
//   qs ipc -c <shell> call <target> <function>
// Targets without a handler yet (system, settings) arrive with their panels; tests/test_hypr.py lists them.
Scope {
    id: root

    required property var bars
    required property var osd
    required property var launcher
    required property var clipboard
    required property var cheatsheet
    required property var wallpaper
    required property var network
    required property var volume
    required property var calendar
    required property var music
    required property var power

    IpcHandler {
        target: "bar"
        function toggleAutohide(): void { root.bars.toggleAutohide(); }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { root.osd.showBrightness(); }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcher.toggle(); }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.clipboard.toggle(); }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.cheatsheet.toggle(); }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.wallpaper.toggle(); }
    }

    IpcHandler {
        target: "network"
        function toggle(): void { root.network.toggle(); }
    }

    IpcHandler {
        target: "volume"
        function toggle(): void { root.volume.toggle(); }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.calendar.toggle(); }
    }

    IpcHandler {
        target: "music"
        function toggle(): void { root.music.toggle(); }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.power.toggle(); }
    }
}
