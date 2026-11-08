import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// Game mode (SUPER + G, or Settings → System). Hyprland and the shell drop
// what costs frames (theme.toml effects.game_mode, written by `tfem settings
// set`: no animations, blur or shadows, fullscreen games may tear and go
// straight to the screen); the desktop widgets stop, the screen never sleeps,
// notifications wait. While it is on, Feral GameMode (gamemoded) is asked for
// its own optimisations, such as the CPU in performance; stopping the request
// ends them.
Scope {
    id: root

    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"
    property bool feral: false          // gamemoded is installed
    property var waiting: null          // a switch asked while the last one is written

    function toggle() {
        set(!Theme.gameMode);
    }

    function set(on) {
        Theme.gameMode = on;            // the shell follows at once
        if (writer.running) {
            waiting = on;
            return;
        }
        writer.command = [cli, "settings", "set", "effects.game_mode=" + on];
        writer.running = true;
    }

    Process {
        id: writer
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0)
                console.warn("game mode: not saved:", errors.text.trim());
            if (root.waiting !== null) {
                const next = root.waiting;
                root.waiting = null;
                root.set(next);
            }
        }
    }

    // `gamemoded -r` asks for GameMode and waits; ending it ends the request.
    Process {
        running: root.feral && Theme.gameMode
        command: ["gamemoded", "-r"]
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v gamemoded"]
        onExited: code => root.feral = code === 0
    }

    IpcHandler {
        target: "gamemode"

        function toggle(): void {
            root.toggle();
        }
    }
}
