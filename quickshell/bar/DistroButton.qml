import QtQuick
import "../theme"
import "../components"
import "../components/logos.js" as Logos

// The distro's logo in the accent color, at the left of the bar; a click
// opens the Settings window. A system without a logo here shows the gear.
Pill {
    id: button

    property string distro: ""

    padding: 8

    Image {
        anchors.verticalCenter: parent.verticalCenter
        visible: Logos.has(button.distro)
        width: 18
        height: 18
        sourceSize: Qt.size(36, 36)
        source: visible ? Logos.source(button.distro, Theme.accent.toString()) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: !Logos.has(button.distro)
        name: "settings"
        color: Theme.accent
        size: 18
    }
}
