import QtQuick

// One instance per TopBar/monitor. Panels retain their own content, IPC and focus.
Item {
    id: root
    required property var controlCenter
    required property var calendar
    required property var quickSettings
    required property var lockController
    property var activePanel: null
    readonly property var panels: [controlCenter, calendar, quickSettings]
    function changed(panel) {
        if (!panel.opened) {
            if (activePanel === panel) activePanel = null;
            return;
        }
        if (lockController.locked) { panel.dismissImmediately(); return; }
        activePanel = panel;
        for (const other of panels)
            if (other !== panel) other.dismissImmediately();
    }
    function closeAll() {
        for (const panel of panels) panel.dismissImmediately();
        activePanel = null;
    }
    Connections { target: root.controlCenter; function onOpenedChanged() { root.changed(root.controlCenter); } }
    Connections { target: root.calendar; function onOpenedChanged() { root.changed(root.calendar); } }
    Connections { target: root.quickSettings; function onOpenedChanged() { root.changed(root.quickSettings); } }
    Connections {
        target: root.lockController
        function onLockedChanged() { if (root.lockController.locked) root.closeAll(); }
    }
}
