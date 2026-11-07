pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../bar/apps.js" as Apps

// The apps running right now, for the bar: open windows (Wayland toplevels)
// and tray icons (Discord or OBS closed to the tray), one entry per app.
// Focus brings an app forward; quit asks it to leave.
Singleton {
    id: root

    readonly property var windows: ToplevelManager.toplevels.values
    readonly property var trays: SystemTray.items.values
    readonly property var apps: Apps.group(windows.map(describe), trays.map(item => ({
        id: item.id,
        title: item.title,
        tooltip: item.tooltipTitle,
        icon: item.icon,
        applet: item.category === Category.Hardware || item.category === Category.SystemServices
    })))

    // Name and icon from the app's desktop entry, else from its id.
    function describe(toplevel) {
        const entry = toplevel.appId ? DesktopEntries.heuristicLookup(toplevel.appId) : null;
        const icon = entry && entry.icon ? entry.icon : toplevel.appId;
        return {
            appId: toplevel.appId,
            name: entry ? entry.name : toplevel.appId,
            icon: icon ? Quickshell.iconPath(icon, true) : "",
            activated: toplevel.activated
        };
    }

    function windowsOf(app) {
        return app.windows > 0 ? windows.filter(toplevel => Apps.norm(toplevel.appId) === app.key) : [];
    }

    function trayOf(app) {
        return app.tray >= 0 ? trays[app.tray] || null : null;
    }

    // Brings the app forward, then each click moves to its next window. An
    // app only in the tray opens its window.
    function focus(app) {
        const list = windowsOf(app);
        if (list.length === 0) {
            const tray = trayOf(app);
            if (tray)
                tray.activate();
            return;
        }
        const current = list.findIndex(toplevel => toplevel.activated);
        list[(current + 1) % list.length].activate();
    }

    // The process ids of Hyprland's windows are read when a menu opens, so
    // they are known by the time "Quit" is clicked.
    function prepareQuit() {
        Hyprland.refreshToplevels();
    }

    // Quits with the app's own tray entry when there is one (`entry`), else
    // sends SIGTERM to the processes of its windows: the polite "please
    // quit" that apps handle like their own Quit. Without a process id the
    // windows are asked to close.
    function quit(app, entry) {
        if (entry) {
            entry.triggered();
            return;
        }
        const list = windowsOf(app);
        const pids = [];
        for (const toplevel of Hyprland.toplevels.values) {
            const pid = toplevel.lastIpcObject ? toplevel.lastIpcObject.pid : 0;
            if (pid > 0 && list.includes(toplevel.wayland) && !pids.includes(pid))
                pids.push(pid);
        }
        if (pids.length > 0)
            Quickshell.execDetached(["kill", "-s", "TERM"].concat(pids.map(String)));
        else
            list.forEach(toplevel => toplevel.close());
    }
}
