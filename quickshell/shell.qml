import QtQuick
import Quickshell
import "theme"
import "bar"
import "osd"
import "notifications"
import "launcher"
import "ipc"

// Entry point: only composes the parts, each one lives in its own folder.
ShellRoot {
    ThemeFile {}

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Osd { id: osdLayer }
    Notifications {}
    Launcher { id: launcherLayer }
    Shortcuts {
        launcher: launcherLayer
        osd: osdLayer
    }
}
