pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var theme
    required property var sinkAudio
    readonly property int volumePercent: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    readonly property string icon: !sinkAudio || sinkAudio.muted ? "󰝟" : volumePercent < 34 ? "󰕿" : volumePercent < 67 ? "󰖀" : "󰕾"
    signal openRequested
    width: audioText.implicitWidth
    implicitHeight: root.theme.barHeight

    Text {
        id: audioText
        anchors.centerIn: parent
        text: root.icon + " " + root.volumePercent + "%"
        color: root.sinkAudio && root.sinkAudio.muted ? root.theme.textMuted : root.theme.textAlt
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.openRequested();
            } else if (mouse.button === Qt.MiddleButton && root.sinkAudio) {
                root.sinkAudio.muted = !root.sinkAudio.muted;
            } else if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["pavucontrol"]);
            }
        }
        onWheel: function(wheel) {
            if (!root.sinkAudio)
                return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sinkAudio.volume = Math.max(0, Math.min(1, root.sinkAudio.volume + step));
        }
    }

}
