import QtQuick
import "../theme"
import "../components"
import "icons.js" as Icons

// Keyboard layout, sound, network, Bluetooth and battery, each in its
// module color, after the icons of the modes that are on. Clicking opens
// the system panel. `vertical`: one under the other (bar on the left or right).
Pill {
    id: area

    // { keyboard, volume, muted, network (wifi | wired | offline), wifiStrength,
    //   bluetoothOn, bluetoothConnected, hasBattery, battery, charging,
    //   quiet, awake, game, modes: { saver, night, presentation, focus } }
    property var status: ({})
    readonly property var s: status || {}

    spacing: 10

    Repeater {
        model: Icons.modes(area.s)

        Icon {
            required property string modelData
            name: modelData
            color: Theme.accent
        }
    }
    Label {
        visible: !area.vertical && !!area.s.keyboard
        text: area.s.keyboard || ""
        small: true
        font.weight: Font.Bold
    }
    Icon {
        color: area.s.muted ? Theme.muted : Theme.modules.audio
        name: Icons.volume(area.s)
    }
    Icon {
        color: area.s.network === "offline" || !area.s.network ? Theme.muted : Theme.modules.wifi
        name: Icons.network(area.s)
    }
    Icon {
        color: area.s.bluetoothOn ? Theme.modules.bluetooth : Theme.muted
        name: Icons.bluetooth(area.s)
    }
    Icon {
        visible: !!area.s.hasBattery
        color: area.s.battery < 0.15 && !area.s.charging ? Theme.red : Theme.modules.battery
        name: Icons.battery(area.s)
    }
    Label {
        visible: !!area.s.hasBattery
        text: Math.round((area.s.battery || 0) * 100) + (area.vertical ? "" : "%")
        small: true
    }
}
