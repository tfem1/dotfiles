pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Do not disturb and stay awake, kept in the shell's state folder so a
// shell restart keeps them.
Singleton {
    id: root

    property bool doNotDisturb: false
    property bool stayAwake: false
    property bool ready: false    // saved state read (or missing): changes may be written

    function save() {
        file.setText(JSON.stringify({ doNotDisturb: root.doNotDisturb, stayAwake: root.stayAwake }));
    }

    onDoNotDisturbChanged: if (ready) save()
    onStayAwakeChanged: if (ready) save()

    FileView {
        id: file
        path: Quickshell.statePath("session.json")
        onLoaded: {
            try {
                const data = JSON.parse(file.text());
                root.doNotDisturb = !!data.doNotDisturb;
                root.stayAwake = !!data.stayAwake;
            } catch (error) {
                console.warn("session: cannot read the saved state:", error);
            }
            root.ready = true;
        }
        // First start: no file yet.
        onLoadFailed: root.ready = true
    }
}
