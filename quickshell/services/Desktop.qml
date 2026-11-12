pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import Quickshell.Io

// Workspaces 1 to 10 for the bar, under Hyprland (Quickshell.Hyprland), Sway
// (Quickshell.I3, Sway's i3 IPC) or Niri (`niri msg`: the workspaces of the
// focused screen, read again on every workspace event).
Singleton {
    id: root

    readonly property string compositor: Compositor.name
    property var niriWorkspaces: []     // `niri msg --json workspaces`

    readonly property var workspaces: {
        const list = [];
        for (let id = 1; id <= 10; id++)
            list.push(Object.assign({ id: id, focused: false, occupied: false, urgent: false }, known(id)));
        return list;
    }

    // What the compositor says about workspace `id`.
    function known(id) {
        if (compositor === "niri") {
            const focused = niriWorkspaces.find(w => w.is_focused);
            const output = focused ? focused.output : null;
            const w = niriWorkspaces.find(entry => entry.idx === id && entry.output === output);
            return w ? { focused: w.is_focused, occupied: w.active_window_id !== null, urgent: !!w.is_urgent } : {};
        }
        if (compositor === "sway") {
            const w = I3.workspaces.values.find(entry => entry.number === id);
            // Sway keeps a workspace only while it has windows or focus.
            return w ? { focused: w.focused, occupied: true, urgent: w.urgent } : {};
        }
        const w = Hyprland.workspaces.values.find(entry => entry.id === id);
        const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        return { focused: id === focusedId, occupied: !!w && w.toplevels.values.length > 0, urgent: !!w && w.urgent };
    }

    function focus(id) {
        if (compositor === "niri") {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(id)]);
        } else if (compositor === "sway") {
            I3.dispatch(`workspace number ${id}`);
        } else {
            const workspace = Hyprland.workspaces.values.find(w => w.id === id);
            if (workspace)
                workspace.activate();
            else if (Hyprland.usingLua)
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
            else
                Hyprland.dispatch(`workspace ${id}`);
        }
    }

    // Niri: the list, then again on each workspace event.
    Process {
        id: niriList
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.niriWorkspaces = JSON.parse(text);
                } catch (error) {
                    console.warn("desktop: cannot read niri's workspaces:", error);
                }
            }
        }
    }
    Process {
        running: root.compositor === "niri"
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("\"Workspace"))
                    niriList.running = true;
            }
        }
        onRunningChanged: if (running) niriList.running = true
    }
}
