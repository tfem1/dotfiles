import QtQuick
import "../theme"
import "../components"
import "../components/logos.js" as Logos

// The distro's logo in the accent color, at the left of the bar; a click
// opens the Settings window. Another Linux shows Tux; no os-release, the gear.
Pill {
    id: button

    property string distro: ""
    readonly property string logo: Logos.logoFor(distro)

    padding: 8

    Image {
        visible: button.logo !== ""
        width: 18
        height: 18
        sourceSize: Qt.size(36, 36)
        source: visible ? Logos.source(button.logo, Theme.accent.toString()) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Icon {
        visible: button.logo === ""
        name: "settings"
        color: Theme.accent
        size: 18
    }
}
