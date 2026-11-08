import QtQuick
import Quickshell
import Quickshell.Io
import "settings.js" as Settings

// The settings, read with `tfem settings get` and written with `tfem
// settings set` (which regenerates the theme), one write at a time. A change
// shows at once in `values`, before the write ends; once read back it is
// the saved value, and a write that failed shows the saved value again.
Scope {
    id: store

    required property string cli
    property var settings: ({ values: {}, themes: [], folders: {} })
    property var asked: ({})            // changes not read back yet
    readonly property var values: Settings.overlay(settings.values, asked)
    readonly property bool busy: writer.running
    property var queue: []              // writes waiting for the one running
    property var writing: []            // keys of the write running
    signal written(var keys)
    signal failed(var keys)             // their saved value shows again

    function refresh() {
        reader.running = true;
    }

    // Shows `changes` ({ key: value }) at once, then writes them.
    function change(changes) {
        asked = Object.assign({}, asked, changes);
        write(Settings.pairs(changes));
    }

    function write(pairs) {
        if (writer.running) {
            queue = queue.concat([pairs]);
            return;
        }
        writing = pairs.map(pair => pair.split("=")[0]);
        writer.command = [cli, "settings", "set"].concat(pairs);
        writer.running = true;
    }

    Process {
        id: reader
        command: [store.cli, "settings", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    store.settings = JSON.parse(text);
                    store.asked = Settings.settle(store.settings.values, store.asked);
                } catch (error) {
                    console.warn("settings: cannot read them:", error);
                }
            }
        }
    }

    Process {
        id: writer
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0) {
                console.warn("settings: not applied:", errors.text.trim());
                store.asked = Settings.drop(store.asked, store.writing);
                store.failed(store.writing);
            } else {
                store.written(store.writing);
            }
            store.writing = [];
            reader.running = true;
            if (store.queue.length > 0) {
                const next = store.queue[0];
                store.queue = store.queue.slice(1);
                store.write(next);
            }
        }
    }
}
