import QtQuick
import QtTest
import ".."
TestCase {
    name: "TabPage"
    visible: true
    when: windowShown
    width: 400; height: 300
    Theme { id: testTheme }
    TabPage { id: page; theme: testTheme; width: 400; height: 300 }
    function cleanup() { page.selected = false; tryCompare(page,"opacity",0); }
    function test_outgoingPageNeverAcceptsInput() {
        page.selected = true; tryCompare(page,"opacity",1);
        page.selected = false;
        verify(!page.enabled);
        verify(page.visible);
        tryCompare(page,"opacity",0);
        verify(!page.visible);
    }
    function test_reverseDirection() {
        page.direction = -1; page.selected = true;
        verify(page.offset < 0);
        tryCompare(page,"offset",0);
        page.selected = false;
        tryCompare(page,"offset",testTheme.tabTravel);
    }
    function test_rapidTabChangesSettle() {
        for(let i=0;i<5;i++){page.selected=true;wait(20);page.selected=false;wait(20);}
        page.selected=true;
        tryCompare(page,"opacity",1);
        tryCompare(page,"offset",0);
        verify(page.enabled);
    }
}
