import QtQuick
import QtTest
import ".."

TestCase {
    id: suite
    name: "BarMedia"
    when: windowShown
    visible: true
    width: 400; height: 100
    Theme { id: testTheme }
    QtObject {
        id: player
        property string trackTitle: "Hi"
        property string identity: "Pear Desktop"
        property bool isPlaying: true
        property bool canTogglePlaying: true
        property bool canRaise: true
        property int toggles: 0
        property int raises: 0
        function togglePlaying() { toggles++; }
        function raise() { raises++; }
    }
    BarMedia { id: bar; theme: testTheme; mediaPlayer: player }
    SignalSpy { id: opened; target: bar; signalName: "openRequested" }
    function init() { bar.mediaPlayer=player; player.trackTitle="Hi"; opened.clear(); }
    function test_shortTitlesShrinkAndLongTitlesStayBounded() {
        tryCompare(bar,"width",bar.implicitWidth);
        const shortWidth=bar.width;
        verify(shortWidth<testTheme.barMediaMaxWidth);
        player.trackTitle="A very long music title that must not take the entire top bar";
        tryCompare(bar,"width",testTheme.barMediaMaxWidth);
        player.trackTitle="Oi";
        tryCompare(bar,"width",bar.implicitWidth);
        verify(bar.width<testTheme.barMediaMaxWidth);
        const label=findChild(bar,"barMediaTitle");
        verify(label.width>=label.implicitWidth-1,"short title should not be elided");
    }
    function test_identityAndLiteralTitle() {
        player.trackTitle="";
        compare(findChild(bar,"barMediaTitle").text,"Pear Desktop");
        player.trackTitle="<b>Oi</b>";
        compare(findChild(bar,"barMediaTitle").textFormat,Text.PlainText);
    }
    function test_hiddenWithoutPlayerAndClicksPreserved() {
        tryCompare(bar,"width",bar.implicitWidth);
        mouseClick(bar,bar.width/2,bar.height/2,Qt.LeftButton);
        compare(opened.count,1);
        const toggles=player.toggles, raises=player.raises;
        mouseClick(bar,bar.width/2,bar.height/2,Qt.MiddleButton);
        mouseClick(bar,bar.width/2,bar.height/2,Qt.RightButton);
        compare(player.toggles,toggles+1);compare(player.raises,raises+1);
        bar.mediaPlayer=null;
        compare(bar.visible,false);tryCompare(bar,"width",0);
    }
}
