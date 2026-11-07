import QtQuick
import Quickshell

// One bar per screen, and what they share: autohide (SUPER + A).
Scope {
    id: root

    property bool autohide: false

    function toggleAutohide() {
        autohide = !autohide;
    }

    Variants {
        model: Quickshell.screens

        Bar {
            autohide: root.autohide
        }
    }
}
