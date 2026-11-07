import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../overlay"

// Connects the volume panel to PipeWire. Nodes are bound (full details:
// app names, icons, volumes) only while the panel is open.
Scope {
    id: root

    property bool open: false

    readonly property var nodes: Pipewire.nodes.values.filter(node => node.audio)
    readonly property var outputs: root.nodes.filter(node => node.isSink && !node.isStream)
    readonly property var inputs: root.nodes.filter(node => !node.isSink && !node.isStream)
    readonly property var streams: root.nodes.filter(node => node.isSink && node.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function toggle() {
        open = !open;
    }

    function label(node) {
        return node ? node.description || node.nickname || node.name : "";
    }

    function level(node, devices, current) {
        return {
            name: root.label(node),
            volume: node && node.audio ? node.audio.volume : 0,
            muted: node && node.audio ? node.audio.muted : false,
            devices: devices.map(device => ({ ref: device, name: root.label(device), current: device === current }))
        };
    }

    function app(stream) {
        const props = stream.properties;
        const icon = props["application.icon-name"] || "";
        return {
            ref: stream,
            name: props["application.name"] || root.label(stream),
            detail: props["media.name"] || "",
            iconSource: icon ? Quickshell.iconPath(icon, true) : "",
            volume: stream.audio.volume,
            muted: stream.audio.muted
        };
    }

    PwObjectTracker {
        objects: root.open ? root.outputs.concat(root.inputs, root.streams) : []
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "volume"
            dim: 0.2
            onDismissed: root.open = false

            VolumeContent {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: implicitWidth
                height: implicitHeight
                output: root.level(root.sink, root.outputs, root.sink)
                input: root.level(root.source, root.inputs, root.source)
                apps: root.streams.map(stream => root.app(stream))
                // Volume stops at 100 %, like the volume keys (wpctl -l 1).
                onOutputMoved: volume => { if (root.sink) root.sink.audio.volume = volume; }
                onOutputMuteToggled: { if (root.sink) root.sink.audio.muted = !root.sink.audio.muted; }
                onOutputChosen: ref => Pipewire.preferredDefaultAudioSink = ref
                onInputMoved: volume => { if (root.source) root.source.audio.volume = volume; }
                onInputMuteToggled: { if (root.source) root.source.audio.muted = !root.source.audio.muted; }
                onInputChosen: ref => Pipewire.preferredDefaultAudioSource = ref
                onAppMoved: (ref, volume) => ref.audio.volume = volume
                onAppMuteToggled: ref => ref.audio.muted = !ref.audio.muted
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
