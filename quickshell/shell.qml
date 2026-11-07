import QtQuick
import Quickshell
import "theme"
import "bar"
import "osd"
import "notifications"
import "launcher"
import "clipboard"
import "cheatsheet"
import "wallpaper"
import "network"
import "volume"
import "calendar"
import "music"
import "power"
import "system"
import "ipc"

// Entry point: only composes the parts, each one lives in its own folder.
ShellRoot {
    ThemeFile {}

    WallpaperLayer {}
    Bars {
        id: barLayer
        onStatusClicked: networkLayer.toggle()
        onClockClicked: calendarLayer.toggle()
        onPowerClicked: powerLayer.toggle()
    }
    Osd { id: osdLayer }
    Notifications { id: notificationLayer }
    Launcher { id: launcherLayer }
    Clipboard { id: clipboardLayer }
    Cheatsheet { id: cheatsheetLayer }
    Selector { id: wallpaperLayer }
    NetworkPanel { id: networkLayer }
    VolumePanel { id: volumeLayer }
    Calendar { id: calendarLayer }
    MusicPanel { id: musicLayer }
    PowerMenu { id: powerLayer }
    SystemPanel {
        id: systemLayer
        notifications: notificationLayer
        power: powerLayer
        system: systemLayer
    }

    Shortcuts {
        bars: barLayer
        osd: osdLayer
        launcher: launcherLayer
        clipboard: clipboardLayer
        cheatsheet: cheatsheetLayer
        wallpaper: wallpaperLayer
        network: networkLayer
        volume: volumeLayer
        calendar: calendarLayer
        music: musicLayer
        power: powerLayer
        system: systemLayer
    }
}
