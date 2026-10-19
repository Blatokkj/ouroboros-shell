import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Opt-in native surface test. Radios, brightness and session lock are fake.
ShellRoot {
    Theme { id: theme }
    QtObject { id: lock; property bool locked: false }
    QtObject {
        id: network
        property var wifiDevice: null
        property var bluetoothAdapter: null
        property bool wifiEnabled: true
        property string scanMode: ""
        function setScanning(owner, mode) { scanMode = mode; }
        function toggleWifi() { wifiEnabled = !wifiEnabled; }
    }
    QtObject {
        id: brightness
        property int percent: 50
        property string error: ""
        function setPercent(value) { percent = Math.max(1, Math.min(100, value)); }
    }
    PanelWindow {
        id: bar
        readonly property date clockDate: new Date()
        anchors { top: true; left: true }
        // Match the real bar's surface origin for physical-edge assertions.
        margins { top: 0; left: 100 }
        implicitWidth: 600
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { width: 0; height: 0 }
    }
    AnimatedPopup {
        id: center
        edgeAttached: true
        theme: theme
        barWindow: bar
        panelItem: body
        preferredWidth: 240
        preferredHeight: 100
        anchor.window: bar
        anchor.rect.y: 2
        Rectangle {
            id: body
            width: 240; height: 100
            color: theme.panelBackground
            Keys.onEscapePressed: center.opened = false
        }
    }
    CalendarPopup { id: calendar; theme: theme; barWindow: bar }
    QuickSettingsPopup {
        id: quick
        theme: theme
        barWindow: bar
        network: network
        brightness: brightness
        sinkAudio: null
    }
    PanelCoordinator {
        controlCenter: center; calendar: calendar; quickSettings: quick; lockController: lock
    }
    QtObject {
        id: fakeProfile
        property string displayName: "Teste isolado"
        property string computerName: "White"
        property string avatar: ""
        property string userName: "teste"
        property string hostName: "teste"
        property bool ready: true
        property bool saving: false
        property string message: ""
        property bool error: false
        signal saved()
        function save(name,computer,photo) { return false; }
    }
    AnimatedPopup {
        id: profilePopup
        theme: theme; barWindow: bar
        preferredWidth: 480; preferredHeight: 390
        panelItem: profileBody
        focusSuspended: profilePage.choosingPhoto
        anchor.window: bar
        Rectangle {
            id: profileBody
            width: 480; height: 390
            color: theme.background
            ProfilePage {
                id: profilePage
                anchors { fill: parent; margins: 12 }
                theme: theme; profile: fakeProfile; active: profilePopup.opened
            }
        }
    }
    IpcHandler {
        target: "panel-test"
        function open(which: string): void {
            if (which === "calendar") calendar.opened = true;
            else if (which === "wifi") quick.openFor("wifi", 200);
            else center.opened = true;
        }
        function close(): void { center.opened = false; calendar.opened = false; quick.opened = false; }
        function lockTest(value: bool): void { lock.locked = value; }
        function narrow(): void { bar.implicitWidth = 340; }
        function profileOpen(): void { profilePopup.opened = true; }
        function photoChoose(): void { profilePage.pickPhoto(); }
        function photoDismiss(): void { profilePage.cancelPhoto(); }
        function photoCancel(): void { profilePopup.opened = false; }
        function status(): string {
            const state = p => ({opened:p.opened, rendered:p.visible, animating:p.animating,
                input:p.inputActive, enabled:p.panelItem.enabled, width:p.width, scale:p.layoutScale,
                top:p.panelItem.mapToItem(p.contentItem,0,0).y,
                globalY:p.contentItem.mapToGlobal(0,0).y,
                contentWidth:p.panelItem.mapToItem(p.contentItem,p.panelItem.width,0).x
                    - p.panelItem.mapToItem(p.contentItem,0,0).x});
            return JSON.stringify({center:state(center), calendar:state(calendar), quick:state(quick), scan:network.scanMode,
                profile:state(profilePopup), choosingPhoto:profilePage.choosingPhoto});
        }
    }
}
