import QtQuick
import Quickshell
import Quickshell.Io

// The warmer screen of night mode, with hyprsunset at 4000 K: when you run
// hyprsunset already, it is asked through hyprctl and reset to your profile
// after; otherwise one is started here and the screen set back to normal
// before it stops.
Scope {
    id: filter

    property bool active: false
    property string owner: ""           // "" off, "ours" started here, "yours" already running

    function run(command) {
        Quickshell.execDetached(["sh", "-c", command]);
    }

    onActiveChanged: {
        if (active) {
            check.running = true;
        } else if (owner === "yours") {
            run("hyprctl hyprsunset reset");
            owner = "";
        } else if (owner === "ours") {
            run("hyprctl hyprsunset identity");
            stop.restart();
            owner = "";
        }
    }

    Process {
        id: sunset
        command: ["hyprsunset", "--temperature", "4000"]
    }
    Process {
        id: check
        command: ["pidof", "hyprsunset"]
        onExited: code => {
            if (!filter.active)
                return;
            filter.owner = code === 0 ? "yours" : "ours";
            if (code === 0)
                filter.run("hyprctl hyprsunset temperature 4000");
            else
                sunset.running = true;
        }
    }
    // The screen is back to normal before our hyprsunset goes.
    Timer {
        id: stop
        interval: 500
        onTriggered: sunset.running = false
    }
}
