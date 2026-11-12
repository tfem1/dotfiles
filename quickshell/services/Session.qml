pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The modes kept by the shell (SUPER + K): do not disturb, stay awake
// (coffee), night, focus and presentation, in the shell's state folder so a
// shell restart keeps them. Game mode and power saver live in theme.toml
// (Hyprland follows them too): see Theme.
Singleton {
    id: root

    property bool doNotDisturb: false
    property bool stayAwake: false
    property bool night: false        // warmer, dimmer screen; notifications wait
    property bool focus: false        // notifications wait, widgets hidden
    property bool presentation: false // no notification at all, never sleeps, widgets hidden
    property bool ready: false    // saved state read (or missing): changes may be written
    // A screen recording is running (`tfem record`, SUPER + ALT + R): the bar
    // shows a red dot. Told by the script, never saved.
    property bool recording: false

    function save() {
        file.setText(JSON.stringify({
            doNotDisturb: root.doNotDisturb, stayAwake: root.stayAwake, night: root.night,
            focus: root.focus, presentation: root.presentation
        }));
    }

    onDoNotDisturbChanged: if (ready) save()
    onStayAwakeChanged: if (ready) save()
    onNightChanged: if (ready) save()
    onFocusChanged: if (ready) save()
    onPresentationChanged: if (ready) save()

    FileView {
        id: file
        path: Quickshell.statePath("session.json")
        onLoaded: {
            try {
                const data = JSON.parse(file.text());
                root.doNotDisturb = !!data.doNotDisturb;
                root.stayAwake = !!data.stayAwake;
                root.night = !!data.night;
                root.focus = !!data.focus;
                root.presentation = !!data.presentation;
            } catch (error) {
                console.warn("session: cannot read the saved state:", error);
            }
            root.ready = true;
        }
        // First start: no file yet.
        onLoadFailed: root.ready = true
    }

    IpcHandler {
        target: "recording"

        function started(): void {
            root.recording = true;
        }
        function stopped(): void {
            root.recording = false;
        }
    }
}
