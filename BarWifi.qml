pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var theme
    required property var network
    signal openRequested
    width: wifiText.implicitWidth
    implicitHeight: root.theme.barHeight

    Text {
        id: wifiText
        anchors.centerIn: parent
        text: root.network.icon
        color: root.network.limited ? root.theme.warning : root.network.wifiNetwork || root.network.wiredConnected ? root.theme.accent : root.theme.textMuted
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
    }

    MouseArea {
        id: wifiMouse
        property bool longPressed: false
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: longPressed = false
        onPressAndHold: {
            longPressed = true;
            root.openRequested();
        }
        onClicked: {
            if (!longPressed)
                root.network.toggleWifi();
        }
    }

}
