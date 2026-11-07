import QtQuick
import Quickshell
import Quickshell.Io

// Commands sent by the Hyprland keybinds:
//   qs ipc -c <shell> call <target> <function>
// Targets without a handler yet (system, music, calendar, volume, settings) arrive with their panels; tests/test_hypr.py lists them.
Scope {
    id: root

    required property var bars
    required property var osd
    required property var launcher
    required property var clipboard
    required property var cheatsheet
    required property var wallpaper
    required property var network

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
}
