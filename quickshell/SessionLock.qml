pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

Scope {
    id: root

    required property var theme
    required property var stats

    property string wallpaperPath: ""
    property string submittedPassword: ""
    property string authMessage: ""
    property bool authError: false
    property bool authenticating: false
    property int clearRevision: 0

    readonly property bool locked: sessionLock.locked
    readonly property bool secure: sessionLock.secure

    function refreshWallpaper() {
        if (!wallpaperProcess.running)
            wallpaperProcess.running = true;
    }

    function lock() {
        if (sessionLock.locked)
            return;
        root.refreshWallpaper();
        root.submittedPassword = "";
        root.authMessage = "";
        root.authError = false;
        root.authenticating = false;
        root.clearRevision++;
        sessionLock.locked = true;
    }

    function authenticate(password) {
        if (!sessionLock.locked || root.authenticating || password.length === 0)
            return;

        root.authMessage = "Verificando…";
        root.authError = false;
        root.authenticating = true;
        root.clearRevision++;
        if (pam.active && pam.responseRequired) {
            pam.respond(password);
            return;
        }

        root.submittedPassword = password;
        if (!pam.start()) {
            root.authenticating = false;
            root.authError = true;
            root.authMessage = "Não foi possível iniciar a autenticação";
            root.submittedPassword = "";
            root.clearRevision++;
        }
    }

    Component.onCompleted: refreshWallpaper()

    Process {
        id: wallpaperProcess
        command: ["/usr/bin/bash", Quickshell.shellDir + "/scripts/wallpapers", "current"]
        stdout: StdioCollector {
            id: wallpaperOutput
            waitForEnd: true
        }
        onExited: function(exitCode) {
            if (exitCode === 0 && wallpaperOutput.text.trim().length > 0)
                root.wallpaperPath = wallpaperOutput.text.trim();
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (responseRequired) {
                if (responseVisible) {
                    // A visible PAM prompt must never receive the password.
                    respond(String(Quickshell.env("USER")));
                } else if (root.submittedPassword.length > 0) {
                    respond(root.submittedPassword);
                    root.submittedPassword = "";
                } else {
                    // Allow another secret prompt (for example an OTP) without
                    // automatically reusing the login password.
                    root.authenticating = false;
                    root.authMessage = message || "Digite o código de autenticação";
                    root.clearRevision++;
                }
            } else if (message.length > 0 && !message.toLowerCase().includes("password")) {
                root.authMessage = message;
                root.authError = messageIsError;
            }
        }

        onCompleted: function(result) {
            root.authenticating = false;
            root.submittedPassword = "";

            if (result === PamResult.Success) {
                root.authMessage = "";
                root.authError = false;
                sessionLock.locked = false;
            } else {
                root.authError = true;
                root.authMessage = result === PamResult.Error ? "Erro no serviço de autenticação"
                    : result === PamResult.MaxTries ? "Muitas tentativas. Aguarde um momento." : "Senha incorreta ou acesso recusado";
                root.clearRevision++;
            }
        }

        onError: function(error) {
            root.authenticating = false;
            root.submittedPassword = "";
            root.authError = true;
            root.authMessage = "Erro no serviço de autenticação";
            root.clearRevision++;
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        onLockStateChanged: {
            if (!locked) {
                if (pam.active)
                    pam.abort();
                root.authenticating = false;
                root.submittedPassword = "";
                root.authMessage = "";
                root.authError = false;
                root.clearRevision++;
            }
        }

        surface: Component {
            WlSessionLockSurface {
                color: root.theme.background

                LockScreenView {
                    anchors.fill: parent
                    theme: root.theme
                    stats: root.stats
                    wallpaperPath: root.wallpaperPath
                    authMessage: root.authMessage
                    authError: root.authError
                    authenticating: root.authenticating
                    secure: root.secure
                    clearRevision: root.clearRevision
                    onPasswordSubmitted: function(password) { root.authenticate(password); }
                }
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lock(); }
        function status(): string { return root.locked ? "locked" : "unlocked"; }
    }
}
