import QtQuick
import QtTest
import ".."
TestCase {
    name: "PanelReveal"
    Theme { id: testTheme }
    Item { id: panel; width: 200; height: 200 }
    PanelReveal { id: reveal; target: panel; theme: testTheme }
    function cleanup() {
        reveal.shown = false;
        reveal.snapClosed();
        reveal.edgeAttached = false;
        reveal.layoutScale = 1;
    }
    function test_attachedSlidesWholePanelWithoutFadeOrZoom() {
        reveal.edgeAttached = true;
        compare(reveal.slide.y, -panel.height);
        compare(panel.mapToItem(null, 0, 0).y, -panel.height);
        compare(panel.opacity, 1);
        compare(reveal.zoom.xScale, 1);
        reveal.progress = 0.5;
        compare(reveal.slide.y, -panel.height / 2);
        compare(panel.opacity, 1);
        reveal.layoutScale = 0.5;
        // Translation is logical; fit scales travel and content together.
        compare(reveal.slide.y, -panel.height / 2);
        compare(reveal.fit.yScale, 0.5);
        compare(panel.mapToItem(null, 0, 0).y, -panel.height / 4);
        reveal.shown = true;
        tryCompare(reveal, "progress", 1);
        compare(reveal.slide.y, 0);
        reveal.shown = false;
        wait(60);
        const progress = reveal.progress;
        verify(progress > 0 && progress < 1);
        reveal.shown = true;
        compare(reveal.progress, progress);
        tryCompare(reveal, "progress", 1);
        reveal.shown = false;
        tryCompare(reveal, "progress", 0);
        compare(reveal.slide.y, -panel.height);
        verify(!reveal.presented);
    }
    function test_replaysOnEveryOpen() {
        compare(panel.transform.length, 3);
        verify(Math.abs(panel.mapToItem(null, 0, 0).y + testTheme.panelTravel * testTheme.panelStartScale) < 0.001);
        for (let i = 0; i < 3; i++) {
            reveal.shown = true;
            verify(reveal.presented);
            tryCompare(reveal, "progress", 1, 1000);
            compare(panel.opacity, 1);
            compare(panel.mapToItem(null, 0, 0).y, 0);
            reveal.shown = false;
            verify(reveal.presented); // Keep the surface alive while exiting.
            tryCompare(reveal, "progress", 0, 1000);
            verify(!reveal.presented);
        }
    }
    function test_reopenReversesWithoutJump() {
        reveal.shown = true;
        tryCompare(reveal, "progress", 1);
        reveal.shown = false;
        wait(50);
        const midpoint = reveal.progress;
        verify(midpoint > 0 && midpoint < 1);
        reveal.shown = true;
        compare(reveal.progress, midpoint);
        tryCompare(reveal, "progress", 1);
    }
    function test_lockSnapsClosed() {
        reveal.shown = true;
        tryCompare(reveal, "progress", 1);
        reveal.shown = false;
        reveal.snapClosed();
        compare(reveal.progress, 0);
        verify(!reveal.animating && !reveal.presented);
    }
}
