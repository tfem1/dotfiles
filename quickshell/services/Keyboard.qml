pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Active keyboard layout, shortened for the bar: "English (US)" -> "US".
Singleton {
    id: root

    property string layout: ""
    readonly property string short: {
        const inBrackets = layout.match(/\(([^)]+)\)/);
        return (inBrackets ? inBrackets[1] : layout.slice(0, 2)).toUpperCase();
    }

    // Layout switches arrive as "activelayout>>keyboard,Layout name".
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.layout = event.data.slice(event.data.lastIndexOf(",") + 1);
        }
    }

    // Initial layout, read once from the main keyboard.
    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim())
                    return;  // hyprctl missing or not answering: no layout to show
                try {
                    const keyboards = JSON.parse(text).keyboards || [];
                    const main = keyboards.find(k => k.main) || keyboards[0];
                    if (main)
                        root.layout = main.active_keymap;
                } catch (error) {
                    console.warn("keyboard layout:", error);
                }
            }
        }
    }
}
