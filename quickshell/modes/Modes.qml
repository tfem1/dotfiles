import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../services"

// The modes, turned on and off from Settings → Tweaks (SUPER + G flips game
// mode). Game mode and power saver
// are written to theme.toml (`tfem settings set`), so Hyprland drops its
// effects too; only one of the two is on at a time. The others are kept by
// the shell (Session). What each mode does outside the shell lives here:
// - game: Feral GameMode is asked for its optimisations (gamemoded -r);
// - power saver: the power profile goes to power-saver (powerprofilesctl),
//   then back to the one before;
// - night: a warmer screen (NightFilter) and, like power saver, a dimmer one
//   (brightnessctl saves the level and puts it back);
// - sleep: the lock screen, then suspend;
// - screenshot, region: `tfem screenshot`, once the Settings window is gone.
Scope {
    id: root

    required property var locker
    readonly property string cli: Quickshell.env("HOME") + "/.local/bin/tfem"
    property var tools: ({})            // which helpers are installed
    property var waiting: null          // effects asked while the last ones are written
    property string profileBefore: "balanced"

    readonly property var on: ({
        game: Theme.gameMode, saver: Theme.powerSaver, coffee: Session.stayAwake, night: Session.night,
        quiet: Session.doNotDisturb, presentation: Session.presentation, focus: Session.focus
    })
    readonly property bool dimmed: Session.night || Theme.powerSaver

    function flip(mode) {
        if (mode === "game")
            effects(!Theme.gameMode, false);
        else if (mode === "saver")
            effects(false, !Theme.powerSaver);
        else if (mode === "coffee")
            Session.stayAwake = !Session.stayAwake;
        else if (mode === "night")
            Session.night = !Session.night;
        else if (mode === "quiet")
            Session.doNotDisturb = !Session.doNotDisturb;
        else if (mode === "presentation")
            Session.presentation = !Session.presentation;
        else if (mode === "focus")
            Session.focus = !Session.focus;
        else if (mode === "sleep") {
            locker.lock();
            Quickshell.execDetached(["sh", "-c", "sleep 1 && systemctl suspend"]);
        } else if (mode === "shot-full" || mode === "shot-region") {
            shot.kind = mode.slice(5);
            shot.restart();
        }
    }

    // Game mode and power saver: the shell follows at once, theme.toml after.
    function effects(game, saver) {
        Theme.gameMode = game;
        Theme.powerSaver = saver;
        if (writer.running) {
            waiting = [game, saver];
            return;
        }
        writer.command = [cli, "settings", "set", "effects.game_mode=" + game, "effects.power_saver=" + saver];
        writer.running = true;
    }

    // The Settings window is gone after this, so the capture shows the desktop.
    Timer {
        id: shot
        property string kind: "full"
        interval: 350
        onTriggered: Quickshell.execDetached([root.cli, "screenshot", kind])
    }

    function run(command) {
        Quickshell.execDetached(["sh", "-c", command]);
    }

    Process {
        id: writer
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0)
                console.warn("modes: not saved:", errors.text.trim());
            if (root.waiting !== null) {
                const next = root.waiting;
                root.waiting = null;
                root.effects(next[0], next[1]);
            }
        }
    }

    // Which helpers are there: "gamemoded powerprofilesctl hyprsunset brightnessctl".
    Process {
        running: true
        command: ["sh", "-c", "for t in gamemoded powerprofilesctl hyprsunset brightnessctl; do "
            + "command -v $t >/dev/null 2>&1 && printf '%s ' $t; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const tool of text.trim().split(" "))
                    if (tool)
                        found[tool] = true;
                root.tools = found;
            }
        }
    }

    // Game mode: `gamemoded -r` asks for GameMode and waits; ending it ends the request.
    Process {
        running: !!root.tools.gamemoded && Theme.gameMode
        command: ["gamemoded", "-r"]
    }

    // Power saver: remember the profile in use, then save power; back after.
    Process {
        id: profileReader
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const current = text.trim();
                root.profileBefore = current && current !== "power-saver" ? current : "balanced";
                root.run("powerprofilesctl set power-saver");
            }
        }
    }
    Connections {
        target: Theme
        function onPowerSaverChanged() {
            if (!root.tools.powerprofilesctl)
                return;
            if (Theme.powerSaver)
                profileReader.running = true;
            else
                root.run("powerprofilesctl set " + root.profileBefore);
        }
    }

    // Night and power saver: a dimmer screen, the level before kept and put back.
    onDimmedChanged: if (tools.brightnessctl) run(dimmed ? "brightnessctl -q -s set 40%" : "brightnessctl -q -r")

    NightFilter {
        active: !!root.tools.hyprsunset && Session.night
    }

    IpcHandler {
        target: "gamemode"

        function toggle(): void {
            root.flip("game");
        }
    }
}
