pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland state for the bar: workspaces 1 to 10.
Singleton {
    id: root

    readonly property var workspaces: {
        const known = Hyprland.workspaces.values;
        const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        const list = [];
        for (let id = 1; id <= 10; id++) {
            const workspace = known.find(w => w.id === id);
            list.push({
                id: id,
                focused: id === focusedId,
                occupied: !!workspace && workspace.toplevels.values.length > 0,
                urgent: !!workspace && workspace.urgent
            });
        }
        return list;
    }

    function focus(id) {
        const workspace = Hyprland.workspaces.values.find(w => w.id === id);
        if (workspace)
            workspace.activate();
        else if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }
}
