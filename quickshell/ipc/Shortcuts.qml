import QtQuick
import Quickshell
import Quickshell.Io

// Commands sent by the Hyprland keybinds:
//   qs ipc -c <shell> call <target> <function>
// Targets without a handler yet (system, music, wallpaper, calendar, network,
// volume, clipboard, settings, cheatsheet, bar) arrive with their panels.
Scope {
    id: root

    required property var launcher
    required property var osd

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcher.toggle(); }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { root.osd.showBrightness(); }
    }
}
