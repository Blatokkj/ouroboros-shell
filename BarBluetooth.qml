pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var theme
    required property var network
    signal openRequested
    visible: root.network.bluetoothAdapter !== null
    width: visible ? bluetoothText.implicitWidth : 0
    implicitHeight: root.theme.barHeight

    Text {
        id: bluetoothText
        anchors.centerIn: parent
        text: "󰂯"
        color: root.network.bluetoothAdapter && root.network.bluetoothAdapter.enabled ? root.theme.accent : root.theme.textMuted
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
    }

    MouseArea {
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
            if (!longPressed && root.network.bluetoothAdapter)
                root.network.toggleBluetooth();
        }
    }

}
