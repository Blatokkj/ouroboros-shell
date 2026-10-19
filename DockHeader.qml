import QtQuick

// Fixed at the screen edge while the body slides underneath it.
Rectangle {
    id: root
    required property var theme
    property bool showClock: false
    property date date: new Date()
    property string title: "Archblato Shell"
    signal clicked
    color: theme.background
    ClockLabel {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.theme.spaceTiny / 2
        theme: root.theme; date: root.date; visible: root.showClock
    }
    Text {
        anchors.centerIn: parent
        visible: !root.showClock
        text: root.title
        color: root.theme.textMuted
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall }
    }
    Rectangle { width: root.theme.borderFocus; height: parent.height; color: Qt.rgba(root.theme.textMuted.r,root.theme.textMuted.g,root.theme.textMuted.b,0.3) }
    Rectangle { anchors.right: parent.right; width: root.theme.borderFocus; height: parent.height; color: Qt.rgba(root.theme.textMuted.r,root.theme.textMuted.g,root.theme.textMuted.b,0.3) }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: root.theme.panelPadding; rightMargin: root.theme.panelPadding }
        height: 1; color: root.theme.borderSubtle
    }
    MouseArea { anchors.fill: parent; enabled: root.showClock; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
