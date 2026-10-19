import QtQuick
import QtTest
import ".."

TestCase {
    id: testCase
    name: "ActionSlider"
    when: windowShown
    visible: true
    width: 400
    height: 100
    Theme { id: testTheme }
    ActionSlider {
        id: slider
        x: 10; y: 10; width: 300; height: 30
        theme: testTheme
        property real result: -1
        property int starts: 0
        onStarted: starts++
        onCommitted: value => result = value
    }
    function init() {
        slider.value = 0.2;
        slider.result = -1;
        slider.starts = 0;
    }
    function test_clickSeeksToClickedPoint() {
        mouseClick(slider, 150, 15);
        verify(Math.abs(slider.result - 0.5) < 0.01);
        compare(slider.starts, 1);
    }
    function test_dragSurvivesBackendUpdates() {
        mousePress(slider, 64, 15);
        mouseMove(slider, 221, 15);
        slider.value = 0.1; // A live MPRIS update must not erase the drag draft.
        mouseRelease(slider, 221, 15);
        verify(Math.abs(slider.result - 0.75) < 0.01);
    }
    function test_keyboardSteps() {
        slider.forceActiveFocus();
        keyClick(Qt.Key_Right);
        verify(Math.abs(slider.result - 0.22) < 0.001);
    }
    function test_clampsEnds() {
        mouseClick(slider, 0, 15);
        compare(slider.result, 0);
        mouseClick(slider, 299, 15);
        compare(slider.result, 1);
    }
}
