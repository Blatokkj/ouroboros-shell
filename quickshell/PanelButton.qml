import QtQuick

Rectangle {
    id: root
    required property var theme
    property string text: ""
    property bool active: false
    signal clicked
    implicitWidth: label.implicitWidth + 24
    implicitHeight: 32
    radius: 10
    color: active ? theme.accentSoft : mouse.containsMouse ? theme.surfaceAlt : theme.surface
    border.color: active || activeFocus ? theme.accent : theme.borderSubtle
    opacity: enabled ? 1 : 0.4
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Text {
        id: label
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: root.active ? root.theme.accent : root.theme.textAlt
        font { family: root.theme.fontFamily; pixelSize: 11 }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    Behavior on color { ColorAnimation { duration: 140 } }
}
