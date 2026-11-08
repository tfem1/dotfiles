pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../components/logos.js" as Logos

// The system the desktop runs on, from /etc/os-release: "arch", "fedora"...
Singleton {
    id: root

    property string id: ""

    FileView {
        path: "/etc/os-release"
        printErrors: false
        onLoaded: root.id = Logos.distroId(text())
    }
}
