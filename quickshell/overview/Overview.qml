import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../overlay"
import "../services"
import "../theme"
import "overview.js" as OverviewLib

// The workspace overview (SUPER + Tab, `qs ipc call overview toggle`):
// Hyprland's workspaces and windows (Quickshell.Hyprland), each window a
// live picture (ScreencopyView of its Wayland toplevel). Moving a window
// goes through Hyprland's Lua dispatchers. Only loaded while open.
Scope {
    id: root

    property bool open: false

    function toggle() {
        // Niri has its own overview; Sway has none.
        if (Compositor.name === "niri") {
            Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"]);
            return;
        }
        if (Compositor.name !== "hyprland")
            return;
        open = !open;
        if (open) {
            // Window places and sizes, fresh.
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
        }
    }

    function dispatch(command, plain) {
        Hyprland.dispatch(Hyprland.usingLua ? command : plain);
    }

    readonly property var model: {
        const workspaces = Hyprland.workspaces.values.map(workspace => ({
            id: workspace.id,
            monitor: workspace.monitor ? {
                x: workspace.monitor.x, y: workspace.monitor.y, width: workspace.monitor.width,
                height: workspace.monitor.height, scale: workspace.monitor.scale
            } : null
        }));
        const windows = Hyprland.toplevels.values.map(toplevel => {
            const ipc = toplevel.lastIpcObject || {};
            return {
                address: OverviewLib.address(ipc.address || toplevel.address),
                title: toplevel.title, appClass: ipc.class || "", floating: !!ipc.floating,
                workspace: toplevel.workspace ? toplevel.workspace.id : -1,
                at: ipc.at, size: ipc.size, focused: toplevel.activated
            };
        });
        return OverviewLib.model(workspaces, windows, Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1);
    }

    function toplevelFor(address) {
        return Hyprland.toplevels.values.find(toplevel =>
            OverviewLib.address((toplevel.lastIpcObject || {}).address || toplevel.address) === address);
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggle();
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "overview"
            dim: 0.4
            onDismissed: root.open = false

            OverviewContent {
                anchors.fill: parent
                workspaces: root.model
                ratio: Hyprland.focusedMonitor && Hyprland.focusedMonitor.height > 0
                    ? Hyprland.focusedMonitor.width / Hyprland.focusedMonitor.height : 16 / 9
                // A live picture of the window (hyprland-toplevel-export).
                thumbnail: Component {
                    ScreencopyView {
                        readonly property var toplevel: root.toplevelFor(parent.window.address)
                        captureSource: toplevel ? toplevel.wayland : null
                        live: true
                    }
                }
                onWorkspacePicked: id => {
                    root.open = false;
                    root.dispatch(`hl.dsp.focus({ workspace = ${id} })`, `workspace ${id}`);
                }
                onWindowPicked: address => {
                    root.open = false;
                    root.dispatch(OverviewLib.focusCommand(address), `focuswindow address:${address}`);
                }
                onWindowMoved: (address, workspace) => root.dispatch(OverviewLib.moveCommand(address, workspace),
                    `movetoworkspacesilent ${workspace},address:${address}`)
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
