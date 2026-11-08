pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Volume (0 to 1) and mute state of the default output, and whether the
// default microphone is muted.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    // Node audio properties are only valid while the node is tracked.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }
}
