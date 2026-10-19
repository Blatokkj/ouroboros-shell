import QtQuick
import QtTest
import ".."

TestCase {
    name: "QuickToggle"
    when: windowShown
    width: 240; height: 120
    Theme { id: testTheme }
    QuickToggle { id: toggle; theme: testTheme; width: 220; title: "Wi-Fi" }
    SignalSpy { id: clicks; target: toggle; signalName: "clicked" }
    function init() { toggle.available = true; clicks.clear(); toggle.forceActiveFocus(); }
    function test_keyboard() {
        keyClick(Qt.Key_Return); keyClick(Qt.Key_Space); keyClick(Qt.Key_Enter);
        compare(clicks.count, 3);
        verify(toggle.activeFocus);
        verify(toggle.activeFocusOnTab);
    }
    function test_unavailableCannotActivate() {
        toggle.available = false;
        toggle.activate();
        keyClick(Qt.Key_Space);
        compare(clicks.count, 0);
    }
    function test_simpleToggleIsNotNavigation() {
        compare(toggle.navigates, false);
        verify(toggle.checkable);
        compare(toggle.Accessible.name, "Wi-Fi");
    }
}
