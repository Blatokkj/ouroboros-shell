import QtQuick
import QtTest
import ".."

TestCase {
    name: "MusicWingsReveal"
    Theme { id: theme }
    MusicWingsReveal { id: wings; theme: theme }
    function cleanup() { wings.active = false; wings.suppressed = true; wings.suppressed = false; wings.delay = 5000; }
    function test_fullFiveSecondsNeverEarly() {
        compare(wings.delay, 5000);
        const start = Date.now();
        wings.active = true;
        wait(4800);
        verify(!wings.ready); compare(wings.progress, 0);
        tryCompare(wings, "ready", true, 1000);
        verify(Date.now() - start >= 5000);
        tryCompare(wings, "progress", 1);
    }
    function test_leavingTabAndReopeningRestartsDelay() {
        wings.delay = 180;
        wings.active = true; wait(100); wings.active = false;
        wait(150); verify(!wings.ready);
        wings.active = true; wait(100); verify(!wings.ready);
        tryCompare(wings, "ready", true);
        wings.active = false;
        verify(!wings.interactive);
        tryCompare(wings, "progress", 0);
    }
    function test_lockSnapsAndCancelsPendingTimer() {
        wings.delay = 50;
        wings.active = true;
        tryCompare(wings, "progress", 1);
        wings.suppressed = true;
        compare(wings.progress, 0); verify(!wings.ready); verify(!wings.interactive);
        wait(90); compare(wings.progress, 0);
        wings.active = false; wings.suppressed = false;
        wait(90); verify(!wings.ready);
    }
}
