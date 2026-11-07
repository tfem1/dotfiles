import QtQuick
import Quickshell
import "theme"
import "bar"
import "osd"
import "notifications"
import "launcher"
import "clipboard"
import "cheatsheet"
import "ipc"

// Entry point: only composes the parts, each one lives in its own folder.
ShellRoot {
    ThemeFile {}

    Bars { id: barLayer }
    Osd { id: osdLayer }
    Notifications {}
    Launcher { id: launcherLayer }
    Clipboard { id: clipboardLayer }
    Cheatsheet { id: cheatsheetLayer }

    Shortcuts {
        bars: barLayer
        osd: osdLayer
        launcher: launcherLayer
        clipboard: clipboardLayer
        cheatsheet: cheatsheetLayer
    }
}
