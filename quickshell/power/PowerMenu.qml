import QtQuick
import Quickshell
import Quickshell.Io
import "../overlay"

// Runs the power menu's actions. The menu closes first, so the lock screen
// or the session end is not hidden behind it.
Scope {
    id: root

    property bool open: false
    property string uptime: ""

    // Same commands as the keybinds and Hyprland's own example config.
    readonly property var commands: ({
        lock: "pidof hyprlock || hyprlock",
        logout: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'",
        // Locked first, so the session is safe when the computer wakes up.
        suspend: "pidof hyprlock >/dev/null || hyprlock & sleep 1 && systemctl suspend",
        reboot: "systemctl reboot",
        poweroff: "systemctl poweroff"
    })

    function toggle() {
        open = !open;
        if (open)
            uptimeFile.reload();
    }

    function run(action) {
        open = false;
        Quickshell.execDetached(["sh", "-c", root.commands[action]]);
    }

    // "12345.67 ..." seconds since the computer started.
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const seconds = Math.floor(parseFloat(uptimeFile.text()));
            const days = Math.floor(seconds / 86400);
            const hours = Math.floor(seconds % 86400 / 3600);
            const minutes = Math.floor(seconds % 3600 / 60);
            root.uptime = (days ? days + " d " : "") + (days || hours ? hours + " h " : "") + minutes + " min";
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "power"
            onDismissed: root.open = false

            PowerContent {
                anchors.centerIn: parent
                width: implicitWidth
                height: implicitHeight
                uptime: root.uptime
                onChosen: action => root.run(action)
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
