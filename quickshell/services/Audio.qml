pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Volume (0 to 1) and mute state of the default output.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    // Node audio properties are only valid while the node is tracked.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
