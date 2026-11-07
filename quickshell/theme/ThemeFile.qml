import QtQuick
import Quickshell
import Quickshell.Io

// Watches the generated theme.json (next to shell.qml) and pushes its values
// into Theme: `tfem generate` recolors the running shell, no restart needed.
FileView {
    path: Quickshell.shellDir + "/theme.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
        try {
            Theme.apply(JSON.parse(text()));
        } catch (error) {
            console.warn("theme.json could not be read:", error);
        }
    }
}
