import QtQuick
import Quickshell
import Quickshell.Io

// Test entrypoint kept at the config root for QuickShell's import sandbox.
// Use tests/notification-integration.cjs, which creates a private session bus.
ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
    }
    Theme { id: testTheme }
    SystemNotifications { id: notices; theme: testTheme; suppressed: true; popupsEnabled: false }
    IpcHandler {
        target: "test"
        function snapshot(): string { return JSON.stringify(notices.history); }
        function quiet(value: bool): void { notices.doNotDisturb = value; }
        function suppress(value: bool): void { notices.suppressed = value; }
        function action(id: int, action: string): void { notices.invokeAction(id, action); }
        function remove(key: string): void { notices.removeEntry(key); }
        function expireToast(): void { if (notices.model.count) notices.dismiss(notices.model.get(0).uid); }
        function reload(): void { Quickshell.reload(false); }
    }
}
