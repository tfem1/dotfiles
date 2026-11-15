import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../overlay"
import "../services"

// The battery panel, opened by a click on the battery in the bar, on its own
// (Wi-Fi, Bluetooth and sound have theirs). Level and times from UPower,
// the power profile through power-profiles-daemon (PowerProfiles).
Scope {
    id: root

    property bool open: false

    function toggle() {
        open = !open;
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "battery"
            dim: 0.2
            onDismissed: root.open = false

            BatteryContent {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: implicitWidth
                height: implicitHeight
                level: Power.level
                charging: Power.charging
                secondsLeft: Power.device ? (Power.charging ? Power.device.timeToFull : Power.device.timeToEmpty) : 0
                health: Power.device ? Power.device.healthPercentage : 0
                profile: PowerProfiles.profile === PowerProfile.PowerSaver ? "PowerSaver"
                    : PowerProfiles.profile === PowerProfile.Performance ? "Performance" : "Balanced"
                hasPerformance: PowerProfiles.hasPerformanceProfile
                onProfilePicked: name => PowerProfiles.profile = PowerProfile[name]
                onClosed: root.open = false
            }
        }
    }
}
