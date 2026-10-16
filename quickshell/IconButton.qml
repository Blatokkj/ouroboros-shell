import QtQuick

Rectangle {
    id: root

    required property var theme
    property string icon: ""
    property bool active: false
    property bool danger: false
    property string accessibleName: ""
    property real iconOffsetX: 0
    property real iconOffsetY: 0
    signal clicked
    signal rightClicked

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName || icon
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    implicitWidth: 36
    implicitHeight: 36
    radius: height / 2
    color: mouseArea.containsMouse ? theme.surfaceAlt : active ? theme.accentSoft : theme.pillBackground
    border.color: danger ? theme.error : active ? theme.accent : theme.borderSubtle
    border.width: 1
    scale: mouseArea.pressed ? 0.93 : mouseArea.containsMouse ? 1.06 : 1

    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.iconOffsetX
        anchors.verticalCenterOffset: root.iconOffsetY
        text: root.icon
        color: root.danger ? root.theme.error : root.active ? root.theme.accent : root.theme.text
        font {
            family: root.theme.fontFamily
            pixelSize: root.theme.fontSize + 2
            bold: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }

    Behavior on color {
        ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
    }
}
