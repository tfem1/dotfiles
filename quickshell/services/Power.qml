pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery: level (0 to 1) and charging state. Hidden on desktops.
Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isLaptopBattery && device.isPresent
    // Accepts 0-1 and 0-100, whichever the service reports.
    readonly property real level: device ? (device.percentage > 1 ? device.percentage / 100 : device.percentage) : 0
    readonly property bool charging: device !== null && device.state === UPowerDeviceState.Charging
}
