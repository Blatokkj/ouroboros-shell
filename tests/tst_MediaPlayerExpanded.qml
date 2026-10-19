import QtQuick
import QtTest
import ".."

TestCase {
    id: suite
    name: "MediaPlayerExpanded"
    when: windowShown
    visible: true
    width: 480; height: 400
    Theme { id: testTheme }
    QtObject {
        id: testPlayer
        property string dbusName: "org.mpris.MediaPlayer2.chromium.instance123"
        property int uniqueId: 42
        property string trackTitle: "Teste"
        property string trackArtist: "Artista"
        property string trackAlbum: ""
        property string trackArtUrl: ""
        property bool canRaise: false
        property bool canSeek: true
        property bool positionSupported: true
        property bool lengthSupported: true
        property real length: 200
        property bool canTogglePlaying: false
        property bool isPlaying: true
        property bool canGoNext: false
        property bool canGoPrevious: false
        property bool canControl: true
        property bool shuffleSupported: false
        property bool shuffle: false
        property bool loopSupported: false
        property int loopState: 0
    }
    QtObject {
        id: testMedia
        property var player: testPlayer
        property var players: [testPlayer]
        property string label: "Pear Desktop · YT Music"
        property real position: 20
        property real volume: 1
        property bool canSetVolume: true
        property bool repeatTrack: false
        property bool repeatEnabled: false
        property bool canShuffle: true
        property bool shuffled: false
        property bool canRepeat: true
        property string repeatLabel: "Sem repetição"
        property int repeatCalls: 0
        function toggleShuffle() { shuffled = !shuffled; }
        function cycleRepeat() { repeatCalls++; }
        property var seekArgs: []
        function seek(seconds, name, trackId) { seekArgs = [seconds, name, trackId]; }
        function setVolume(value, name) { if (name === testPlayer.dbusName) volume = value; }
    }
    MediaPlayerExpanded {
        id: panel
        width: 456
        height: implicitHeight
        theme: testTheme
        media: testMedia
    }
    function init() { testMedia.seekArgs = []; testMedia.volume = 1; }
    function test_realPlayerSliderPassesNumericTrackIdentity() {
        const seek = findChild(panel, "mediaSeekSlider");
        verify(seek !== null);
        mouseClick(seek, seek.width / 2, seek.height / 2);
        compare(testMedia.seekArgs.length, 3);
        verify(Math.abs(testMedia.seekArgs[0] - 100) < 1);
        compare(testMedia.seekArgs[1], testPlayer.dbusName);
        verify(testMedia.seekArgs[2] === testPlayer.uniqueId, "Track id must remain numeric, not a string");
    }
    function test_volumeUsesControllerNotMprisProperty() {
        const slider = findChild(panel, "mediaVolumeSlider");
        mouseClick(slider, slider.width / 2, slider.height / 2);
        verify(Math.abs(testMedia.volume - 0.5) < .01);
    }
    function test_shuffleAndRepeatUseControllerEvenWithoutMprisSupport() {
        const shuffle = findChild(panel, "mediaShuffleButton");
        const repeat = findChild(panel, "mediaRepeatButton");
        verify(shuffle.visible); verify(repeat.visible);
        const before = testMedia.shuffled;
        mouseClick(shuffle, shuffle.width / 2, shuffle.height / 2);
        compare(testMedia.shuffled, !before);
        const calls = testMedia.repeatCalls;
        mouseClick(repeat, repeat.width / 2, repeat.height / 2);
        compare(testMedia.repeatCalls, calls + 1);
    }
}
