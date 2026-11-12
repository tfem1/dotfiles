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
    //   quiet, awake, game, recording, updates (packages to update),
    //   modes: { saver, night, presentation, focus } }
    property var status: ({})
    signal updatesClicked   // the update icon: opens a terminal that updates
    readonly property var s: status || {}

    spacing: 10

    // Packages to update: the icon and how many; a click updates them.
    Icon {
        visible: area.s.updates > 0
        name: "system_update_alt"
        color: Theme.accent2
        TapHandler { onTapped: area.updatesClicked() }
    }
    Label {
        visible: area.s.updates > 0 && !area.vertical
        text: String(area.s.updates || "")
        small: true
        color: Theme.accent2
        TapHandler { onTapped: area.updatesClicked() }
    }
    Icon {   // recording the screen
        visible: !!area.s.recording
        name: "radio_button_checked"
        color: Theme.red
    }
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
