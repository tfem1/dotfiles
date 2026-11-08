import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../theme"
import "../services"

// The lock screen (SUPER + L, idle, before suspend). The Wayland session
// lock hides every window until PAM accepts your password (pam/password.conf).
// One surface per screen; what is typed is shared. If the shell is not
// running, the keybinds fall back to hyprlock.
Scope {
    id: root

    property bool locked: false
    property string password: ""
    property string failure: ""          // why the last try failed
    property bool checking: false
    readonly property string user: Quickshell.env("USER") || ""

    function lock() {
        if (locked)
            return;
        password = "";
        failure = "";
        locked = true;
    }

    function submit() {
        if (checking || password === "")
            return;
        failure = "";
        checking = true;
        if (!pam.start()) {
            checking = false;
            failure = "The password cannot be checked";
        }
    }

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"
        onResponseRequiredChanged: if (responseRequired) respond(root.password)
        onCompleted: result => {
            root.checking = false;
            root.password = "";
            if (result === PamResult.Success)
                root.locked = false;
            else if (result === PamResult.Failed)
                root.failure = "Wrong password";
            else if (result === PamResult.MaxTries)
                root.failure = "Too many tries: wait a moment";
            else
                root.failure = "The password could not be checked";
        }
        onError: error => {
            root.checking = false;
            root.password = "";
            root.failure = "The password cannot be checked";
            console.warn("lock:", PamError.toString(error));
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: Theme.bg

            LockContent {
                anchors.fill: parent
                user: root.user
                password: root.password
                failure: root.failure
                checking: root.checking
                layout: Keyboard.short
                onTyped: text => root.password = text
                onSubmitted: root.submit()
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}
