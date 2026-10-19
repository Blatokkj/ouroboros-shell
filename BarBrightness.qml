pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var theme
    required property var brightness
    signal openRequested
    width: brightnessText.implicitWidth
    implicitHeight: root.theme.barHeight

    Text {
        id: brightnessText
        anchors.centerIn: parent
        text: "󰃠 " + root.brightness.percent + "%"
        color: root.theme.textAlt
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openRequested()
        onWheel: function(wheel) {
            root.brightness.setPercent(root.brightness.percent + (wheel.angleDelta.y > 0 ? 5 : -5));
        }
    }

}
