pragma Singleton
import QtQuick
import Quickshell

// The compositor the shell runs under, from the socket it gives its clients:
// "niri", "sway", "hyprland", or "" for another one. The rest of the shell
// asks it which commands to use (workspaces, log out, keyboard layout).
Singleton {
    readonly property string name: Quickshell.env("NIRI_SOCKET") ? "niri"
        : Quickshell.env("SWAYSOCK") ? "sway"
        : Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "hyprland" : ""

    // Ends the session.
    readonly property string logout: ({
        niri: "niri msg action quit --skip-confirmation",
        sway: "swaymsg exit",
        hyprland: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
    })[name] || "loginctl terminate-session \"$XDG_SESSION_ID\""

    // Next keyboard layout.
    readonly property var nextLayout: ({
        niri: ["niri", "msg", "action", "switch-layout", "next"],
        sway: ["swaymsg", "input", "type:keyboard", "xkb_switch_layout", "next"],
        hyprland: ["hyprctl", "switchxkblayout", "all", "next"]
    })[name] || []
}
