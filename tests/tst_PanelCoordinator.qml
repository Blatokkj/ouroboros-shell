import QtQuick
import QtTest
import ".."

TestCase {
    name: "PanelCoordinator"
    QtObject { id: center; property bool opened: false; function dismissImmediately() { opened = false; } }
    QtObject { id: calendarPanel; property bool opened: false; function dismissImmediately() { opened = false; } }
    QtObject { id: quick; property bool opened: false; function dismissImmediately() { opened = false; } }
    QtObject { id: lock; property bool locked: false }
    PanelCoordinator { id: coordinator; controlCenter: center; calendar: calendarPanel; quickSettings: quick; lockController: lock }
    QtObject { id: secondCenter; property bool opened: false; function dismissImmediately() { opened = false; } }
    QtObject { id: secondCalendar; property bool opened: false; function dismissImmediately() { opened = false; } }
    QtObject { id: secondQuick; property bool opened: false; function dismissImmediately() { opened = false; } }
    PanelCoordinator { id: second; controlCenter: secondCenter; calendar: secondCalendar; quickSettings: secondQuick; lockController: lock }
    function cleanup() { coordinator.closeAll(); second.closeAll(); lock.locked = false; }
    function test_exclusiveInEveryOrder() {
        const panels = [center, calendarPanel, quick];
        for (const first of panels) for (const next of panels) {
            first.opened = true;
            next.opened = true;
            compare(coordinator.activePanel, next);
            for (const panel of panels) compare(panel.opened, panel === next);
        }
    }
    function test_monitorIsolation() {
        center.opened = true;
        secondCalendar.opened = true;
        verify(center.opened);
        verify(secondCalendar.opened);
        quick.opened = true;
        verify(!center.opened && secondCalendar.opened);
    }
    function test_lockClosesAndRejectsAllPanels() {
        center.opened = true; secondQuick.opened = true;
        lock.locked = true;
        verify(!center.opened && !secondQuick.opened);
        calendarPanel.opened = true;
        verify(!calendarPanel.opened);
        compare(coordinator.activePanel, null);
    }
    function test_closeClearsActivePanel() {
        center.opened = true; center.opened = false;
        compare(coordinator.activePanel, null);
    }
    function test_unlockRestoresEveryPanelAcrossCycles() {
        for (let i = 0; i < 3; i++) {
            center.opened = true;
            lock.locked = true;
            verify(!center.opened);
            lock.locked = false;
            for (const panel of [center, calendarPanel, quick]) {
                panel.opened = true;
                compare(coordinator.activePanel, panel);
                verify(panel.opened);
            }
        }
    }
}
